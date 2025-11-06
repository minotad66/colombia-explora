# Configuración de permisos IAM para el usuario que ejecuta Terraform
# Este archivo intenta crear y adjuntar la política necesaria para el despliegue
#
# ⚠️ IMPORTANTE: Para que esto funcione, necesitas al menos permisos para:
#   - iam:CreatePolicy
#   - iam:AttachUserPolicy
#   - iam:GetUser
#
# Si no tienes estos permisos, Terraform fallará con un error claro.
# En ese caso, necesitas:
#   1. Usar credenciales con permisos administrativos temporalmente, O
#   2. Configurar los permisos manualmente desde la consola de AWS
#
# Ver: CONFIGURAR-PERMISOS-AHORA.md para instrucciones manuales

# Obtener el nombre del usuario desde el ARN
# Nota: data.aws_caller_identity.current ya está declarado en otro archivo
locals {
  # Extraer el nombre del usuario desde el ARN: arn:aws:iam::ACCOUNT:user/USERNAME
  # Usamos data.aws_caller_identity.current que ya existe
  current_user_name = split("/", data.aws_caller_identity.current.arn)[1]
}

# Política IAM para el despliegue de Colombia Explora
# Solo se crea si auto_setup_iam_permissions está habilitado
resource "aws_iam_policy" "deploy_policy" {
  count = var.auto_setup_iam_permissions ? 1 : 0
  name        = "${var.project_name}-deploy-policy"
  description = "Permisos necesarios para desplegar ${var.project_name} en AWS"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAPIGateway"
        Effect = "Allow"
        Action = [
          "apigateway:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudFront"
        Effect = "Allow"
        Action = [
          "cloudfront:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowRDS"
        Effect = "Allow"
        Action = [
          "rds:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowS3"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowLambda"
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowIAM"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:DeleteRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:CreatePolicy",
          "iam:GetPolicy",
          "iam:ListPolicies",
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
          "iam:ListAttachedUserPolicies",
          "iam:ListUserPolicies",
          "iam:GetUser",
          "iam:ListUsers"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEC2"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatch"
        Effect = "Allow"
        Action = [
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-deploy-policy"
      ServiceType = "IAM"
      Purpose     = "Deployment permissions"
    }
  )
}

# Adjuntar la política al usuario actual
resource "aws_iam_user_policy_attachment" "deploy_policy" {
  count      = var.auto_setup_iam_permissions ? 1 : 0
  user       = local.current_user_name
  policy_arn = aws_iam_policy.deploy_policy[0].arn

  depends_on = [aws_iam_policy.deploy_policy]
}

# Output para confirmar que los permisos fueron configurados
output "user_permissions" {
  description = "Información sobre los permisos configurados para el usuario"
  value = var.auto_setup_iam_permissions ? {
    user_name   = local.current_user_name
    policy_arn  = aws_iam_policy.deploy_policy[0].arn
    policy_name = aws_iam_policy.deploy_policy[0].name
    message     = "✅ Permisos IAM configurados automáticamente. Si este output aparece, los permisos están listos."
  } : {
    user_name   = local.current_user_name
    policy_arn  = "N/A - auto_setup_iam_permissions está deshabilitado"
    policy_name = "N/A"
    message     = "⚠️ Configuración automática de permisos deshabilitada. Configura permisos manualmente."
  }
}

