#! /usr/bin/python3

import boto3
from botocore.exceptions import ClientError
import pprint
import time
import hcl
import os
import sys
import random

admin_secret = sys.argv[1]
role_arn = sys.argv[2]

print(admin_secret)
print(role_arn)

#Load variables from kendra variables   file
with open('kendra.tfvars', 'r') as fp: 
    obj = hcl.load(fp) 
    user_secret = obj['user_secret']
    aws_profile = obj['aws_profile']
    volume_name = obj['volume_name']


#Set up clients
session = boto3.Session(profile_name=aws_profile) 
kendra = session.client("kendra")
secretsmanager = session.client("secretsmanager")
account_id = session.client('sts').get_caller_identity().get('Account')

#Get destination bucket from the secrets

kwargs = {'SecretId': user_secret}
response = secretsmanager.get_secret_value(**kwargs)
secrets = eval(response['SecretString'])
s3_bucket_name = secrets['destination_bucket']

print("Create an index")

description = "Index created for the volume named "+volume_name +" based on the user secrets stored in "+user_secret
index_name = "Kendra"+volume_name+str(random.randrange(100))

try:
    index_response = kendra.create_index(
        Description = description,
        Name = index_name,
        RoleArn = role_arn
    )

    pprint.pprint(index_response)

    index_id = index_response["Id"]

    print("Wait for Kendra to create the index.")

    while True:
        # Get index description
        index_description = kendra.describe_index(
            Id = index_id
        )
        # When status is not CREATING quit.
        status = index_description["Status"]
        print("    Creating index. Status: "+status)
        time.sleep(10)
        if status != "CREATING":
            break

    print("Create an S3 data source")

    data_source_name = volume_name
    data_source_description = volume_name + " is the volume being indexed. Set up by "+aws_profile
    data_source_type = "S3"

    #Creatae an S3 data source role
    data_source_role_arn = "arn:aws:iam::"+account_id+":role/KendraAccessS3_access_policy"

    configuration = {"S3Configuration":
        {
            "BucketName": s3_bucket_name,
            'DocumentsMetadataConfiguration': {
                'S3Prefix': '/NAC/Kendra/'+volume_name+'/metadata/'
            },
        },
        
    }

    data_source_response=kendra.create_data_source(
        Configuration = configuration,
        Name = data_source_name,
        Description = description,
        RoleArn = data_source_role_arn,
        Type = data_source_type,
        IndexId = index_id
    )

    pprint.pprint(data_source_response)

    data_source_id = data_source_response["Id"]

    print("Wait for Kendra to create the data source.")

    while True:
        data_source_description = kendra.describe_data_source(
            Id = data_source_id,
            IndexId = index_id
        )
        # When status is not CREATING quit.
        status = data_source_description["Status"]
        print("    Creating data source. Status: "+status)
        time.sleep(10)
        if status != "CREATING":
            break

    print("Synchronize the data source.")

    sync_response = kendra.start_data_source_sync_job(
        Id = data_source_id,
        IndexId = index_id
    )

    pprint.pprint(sync_response)

    print("Wait for the data source to sync with the index.")

    while True:

        jobs = kendra.list_data_source_sync_jobs(
            Id=data_source_id,
            IndexId=index_id
        )

        # There should be exactly one job item in response
        status = jobs["History"][0]["Status"]

        print("    Syncing data source. Status: "+status)
        if status != "SYNCING":
            break
        time.sleep(10)

except  ClientError as e:
        print("%s" % e)

print("Create an experience")

name = "VolumeSearchPoweredByKendra"
description = "Volume Search"
'''
configuration = {"ExperienceConfiguration":
        [{
            "ContentSourceConfiguration":{"DataSourceIds":[data_source_id]},
            "UserIdentityConfiguration":"Username"
        }]
    }
'''
try:
    experience_response = kendra.create_experience(
        Name = name,
        Description = description,
        IndexId = index_id,
        RoleArn = role_arn
    )

    pprint.pprint(experience_response)
    experience_id = experience_response['Id']

    print("Wait for Kendra to create the experience.")

    while True:
        # Get the experience description
        experience_description = kendra.describe_experience(
            Id = experience_id,
            IndexId = index_id
        )
        status = experience_description["Status"]
        print("    Creating experience. Status: "+status)
        time.sleep(60)
        if status != "CREATING":
            experience_endpoints = experience_response["Endpoints"]
            break

except  ClientError as e:
        print("%s" % e)

# Update the user secrets to include the new endpoints for Kendra

kwargs = {'SecretId': user_secret}
secret_response = secretsmanager.get_secret_value(**kwargs)
secrets = eval(secret_response['SecretString'])
secrets['kendra_endpoints']=experience_endpoints
secrets['kendra_index_id'] = index_id
secrets['kendra_datasource_id'] = data_source_id
secrets['kendra_experience_id'] = experience_id

secretsmanager.update_secret(SecretId=secret_response['ARN'], SecretString=secrets)

# Update the admin secrets with the ARN of the 

kwargs = {'SecretId': admin_secret}
admin_secret_response = secretsmanager.get_secret_value(**kwargs)
admin_secrets = eval(admin_secret_response['SecretString'])
admin_secrets[data_source_role_arn]=user_secret
admin_secrets[role_arn]=user_secret
admin_secrets[index_id]=user_secret
admin_secrets[data_source_id]=user_secret
admin_secrets[experience_id]=user_secret

secretsmanager.update_secret(SecretId=admin_secret_response['ARN'], SecretString=admin_secrets)


print("Program ends.")