########################################################
##  Developed By  :   Pradeepta Kumar Sahu
##  Project       :   Nasuni ElasticSearch Integration
##  Organization  :   Nasuni Labs   
#########################################################

 locals { 
  lambda_code_file_name_without_extension = "nac-kendra-discovery"
  lambda_code_extension                   = ".py"
  handler                                 = "lambda_handler"
  resource_name_prefix                    = "nct-NCE-lambda"
}


data "aws_secretsmanager_secret" "user_secrets" {
  name = var.user_secret
}
data "aws_secretsmanager_secret_version" "current_user_secrets" {
  secret_id = data.aws_secretsmanager_secret.user_secrets.id
}   

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_exec_role" {
  name        = "${local.resource_name_prefix}-lambda_exec_role-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
  path        = "/"
  description = "Allows Lambda Function to call AWS services on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",  
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name            = "${local.resource_name_prefix}-lambda_exec-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
    Application     = "Nasuni Analytics Connector with Kendra"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

resource "aws_iam_role" "kendra_lambda_exec_role" {
  name        = "${local.resource_name_prefix}-kendra_exec_role-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
  path        = "/"
  description = "Allows Kendra Function to call AWS services on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",  
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "kendra.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name            = "${local.resource_name_prefix}-kendra_exec-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
    Application     = "Nasuni Analytics Connector with Kendra"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}



############## CloudWatch Integration for Lambda ######################
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.resource_name_prefix}-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
  retention_in_days = 14

  tags = {
    Name            = "${local.resource_name_prefix}-lambda_log_group-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
    Application     = "Nasuni Analytics Connector with Kendra"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

# AWS Lambda Basic Execution Role
resource "aws_iam_policy" "lambda_logging" {
  name        = "${local.resource_name_prefix}-lambda_logging_policy-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
  tags = {
    Name            = "${local.resource_name_prefix}-lambda_logging_policy-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
    Application     = "Nasuni Analytics Connector with Kendra"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

############## IAM policy for accessing S3 from a lambda ######################
resource "aws_iam_policy" "s3_GetObject_access" {
  name        = "${local.resource_name_prefix}-s3_GetObject_access_policy-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
  path        = "/"
  description = "IAM policy for accessing S3 from a lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::*"
        }
    ]
}
EOF
  tags = {
    Name            = "${local.resource_name_prefix}-s3_GetObject_access_policy-${local.lambda_code_file_name_without_extension}-${random_id.kendra_unique_id.hex}"
    Application     = "Nasuni Analytics Connector with Kendra"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }

}

resource "aws_iam_role_policy_attachment" "s3_GetObject_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.s3_GetObject_access.arn
}


############## IAM policy for accessing Secret Manager from a lambda ######################
resource "aws_iam_policy" "GetSecretValue_access" {
  name        = "GetSecretValue_access_policy-${random_id.kendra_unique_id.hex}"
  path        = "/"
  description = "IAM policy for accessing secretmanager from a lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${data.aws_secretsmanager_secret.user_secrets.arn}"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${data.aws_secretsmanager_secret.user_secrets.arn}"
        }
    ]
}
EOF
  tags = {
    Name            = "GetSecretValue_access_policy"
    Application     = "Nasuni Analytics Connector with Kendra"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

resource "aws_iam_role_policy_attachment" "GetSecretValue_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.GetSecretValue_access.arn
}

############## IAM policy for enabling Kendra to access CloudWatch Logs ######################
data "aws_iam_policy_document" "kendra-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["kendra.amazonaws.com"]
    }
  }
}


resource "aws_iam_policy" "NAC_Kendra_CloudWatch" {
  name        = "NAC_Kendra_CloudWatch_access_policy-${random_id.kendra_unique_id.hex}"
  path        = "/"
  description = "IAM policy for enabling Kendra to access CloudWatch Logs"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "cloudwatch:namespace": "AWS/Kendra"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogGroups"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup"
            ],
            "Resource": [
                "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kendra/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogStreams",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kendra/*:log-stream:*"
            ]
        }
    ]
}
EOF
  tags = {
    Name            = "NAC_Kendra_CloudWatch_access_policy"
    Application     = "Nasuni Analytics Connector with Kendra"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}


resource "aws_iam_role_policy_attachment" "NAC_Kendra_CloudWatch" {
  role       = aws_iam_role.kendra_lambda_exec_role.name
  policy_arn = aws_iam_policy.NAC_Kendra_CloudWatch.arn
}



############## IAM policy for enabling Kendra to access and index S3 ######################
resource "aws_iam_policy" "KendraAccessS3" {
  name        = "KendraAccessS3_access_policy-${random_id.kendra_unique_id.hex}"
  path        = "/"
  description = "IAM policy for enabling Kendra to access and index S3"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::bucket name/*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::bucket name"
            ],
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kendra:BatchPutDocument",
                "kendra:BatchDeleteDocument"
            ],
            "Resource": "arn:aws:kendra:${var.region}:${data.aws_caller_identity.current.account_id}:index/*"
        }
    ]
}
EOF
  tags = {
    Name            = "KendraAccessS3_access_policy"
    Application     = "Nasuni Analytics Connector with Kendra"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

resource "aws_iam_role_policy_attachment" "KendraAccessS3" {
  role       = aws_iam_role.kendra_lambda_exec_role.name
  policy_arn = aws_iam_policy.KendraAccessS3.arn
}

############## IAM policy for enabling Custom Document Enrichment on Kendra ######################
resource "aws_iam_policy" "KendraEnrichment" {
  name        = "KendraCustomDocumentEnrichment_policy"
  path        = "/"
  description = "IAM policy for enabling Custom Document Enrichment in Kendra"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": [
      "s3:GetObject",
      "s3:PutObject"
    ],
    "Resource": [
      "arn:aws:s3:::*/*"
    ],
    "Effect": "Allow"
  },
  {
    "Action": [
      "s3:ListBucket"
    ],
    "Resource": [
      "arn:aws:s3:::*"
    ],
    "Effect": "Allow"
  },
  {
    "Effect": "Allow",
    "Action": [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ],
    "Resource": [
      "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"
    ]
  },
  {
    "Effect": "Allow",
    "Action": [
      "lambda:InvokeFunction"
    ],
    "Resource": "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:*"
  }]
}
EOF
  tags = {
    Name            = "KendraCustomDocumentEnrichment_policy"
    Application     = "Nasuni Analytics Connector with Kendra"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"
  }
}

resource "aws_iam_role_policy_attachment" "KendraEnrichment" {
  role       = aws_iam_role.kendra_lambda_exec_role.name
  policy_arn = aws_iam_policy.KendraEnrichment.arn
}


################################### Attaching AWS Managed IAM Policies ##############################################################

data "aws_iam_policy" "CloudWatchFullAccess" {
  arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "CloudWatchFullAccess" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.CloudWatchFullAccess.arn
}

data "aws_iam_policy" "AWSCloudFormationFullAccess" {
  arn = "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
}

resource "aws_iam_role_policy_attachment" "AWSCloudFormationFullAccess" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.AWSCloudFormationFullAccess.arn
}

data "aws_iam_policy" "AmazonS3FullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.AmazonS3FullAccess.arn
}


resource "null_resource" "kendra_launch" {
  provisioner "local-exec" {
    command = "python3 kendra_launch.py ${var.admin_secret} "
  }
  provisioner "local-exec" {
    when    = destroy
    command = "python3 kendra_destroy.py"
  }
}

resource "random_id" "kendra_unique_id" {
  byte_length = 3
}






