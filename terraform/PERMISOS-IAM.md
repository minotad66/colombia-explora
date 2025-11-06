# 🔐 Permisos IAM Requeridos para el Despliegue

El usuario de AWS necesita los siguientes permisos para desplegar la infraestructura:

## 📋 Políticas Requeridas

### Opción 1: Política de Administrador (MÁS FÁCIL - Solo para pruebas)

Si estás en un entorno de desarrollo/pruebas, puedes usar la política `AdministratorAccess`:

1. Ve a: https://console.aws.amazon.com/iam
2. Users → Tu Usuario (Darwin)
3. Add permissions → Attach policies directly
4. Busca y selecciona: **AdministratorAccess**
5. Click "Next" → "Add permissions"

⚠️ **Nota de Seguridad**: Esta política da acceso completo a AWS. Solo úsala en cuentas de desarrollo/pruebas.

---

### Opción 2: Políticas Específicas (RECOMENDADO - Producción)

Si necesitas permisos más restrictivos, puedes crear una política personalizada con los siguientes permisos:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "apigateway:*",
        "cloudfront:*",
        "rds:*",
        "s3:*",
        "lambda:*",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:GetRole",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:PassRole",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:CreateSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:DeleteSecurityGroup",
        "logs:*",
        "cloudwatch:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Pasos para aplicar esta política:**

1. Ve a: https://console.aws.amazon.com/iam
2. Policies → Create policy
3. JSON → Pega el JSON de arriba
4. Review policy → Nombre: `ColombiaExploraDeployPolicy`
5. Create policy
6. Users → Tu Usuario → Add permissions → Attach policies directly
7. Busca y selecciona: `ColombiaExploraDeployPolicy`
8. Add permissions

---

## ✅ Verificar Permisos

Después de agregar los permisos, verifica que funcionen:

```bash
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name Darwin
```

---

## 🔄 Después de Configurar Permisos

Una vez configurados los permisos, puedes continuar con el despliegue:

```bash
cd terraform
terraform apply
```

---

## ❓ Problemas Comunes

### Error: "AccessDenied"
- **Solución**: Verifica que hayas agregado los permisos correctamente y que hayas esperado 1-2 minutos para que se propaguen.

### Error: "User is not authorized"
- **Solución**: Asegúrate de que la política esté correctamente adjunta a tu usuario.

### Error: "pip: command not found"
- **Solución**: Ya está corregido en el script. Si persiste, verifica que Python 3 esté instalado: `python3 --version`

---

## 📚 Recursos Adicionales

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

