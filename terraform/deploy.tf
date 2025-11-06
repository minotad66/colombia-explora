# Deploy Resources - Automatiza el despliegue de código
# Este archivo maneja el empaquetado y despliegue automático

# ============================================
# Empaquetar Lambda Functions
# ============================================

resource "null_resource" "package_lambda_auth" {
  triggers = {
    # Triggers cuando cambian los archivos fuente
    source_hash = sha256(join("", [
      for f in fileset("${path.module}/../auth", "**/*.py") : filesha256("${path.module}/../auth/${f}")
    ]))
    requirements_hash = filesha256("${path.module}/../auth/requirements.txt")
    lambda_handler = filesha256("${path.module}/../auth/lambda_handler.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/..
      echo "📦 Empaquetando Lambda Auth..."
      chmod +x scripts/package-lambda.sh || true
      ./scripts/package-lambda.sh || {
        echo "❌ Error empaquetando Lambda. Verifica que el script existe y tiene permisos."
        exit 1
      }
      echo "✅ Lambda Auth empaquetado"
    EOT
  }
}

resource "null_resource" "package_lambda_api" {
  triggers = {
    source_hash = sha256(join("", [
      for f in fileset("${path.module}/../api", "**/*.py") : filesha256("${path.module}/../api/${f}")
    ]))
    requirements_hash = filesha256("${path.module}/../api/requirements.txt")
    lambda_handler = filesha256("${path.module}/../api/lambda_handler.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/..
      echo "📦 Empaquetando Lambda API..."
      # El script package-lambda.sh empaqueta ambos, así que solo verificamos
      if [ ! -f "api/api-lambda.zip" ]; then
        echo "⚠️  api-lambda.zip no existe, ejecutando package-lambda.sh..."
        ./scripts/package-lambda.sh || {
          echo "❌ Error empaquetando Lambda API"
          exit 1
        }
      fi
      echo "✅ Lambda API empaquetado"
    EOT
  }

  depends_on = [null_resource.package_lambda_auth]
}

# ============================================
# Subir Lambda Functions a AWS
# ============================================

resource "null_resource" "deploy_lambda_auth" {
  triggers = {
    package_hash = filesha256("${path.module}/../auth/auth-lambda.zip")
    function_name = aws_lambda_function.auth.function_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "📤 Subiendo Lambda Auth a AWS..."
      if aws lambda get-function --function-name ${aws_lambda_function.auth.function_name} --region ${var.aws_region} &>/dev/null; then
        echo "  → Actualizando función existente..."
        aws lambda update-function-code \
          --function-name ${aws_lambda_function.auth.function_name} \
          --zip-file fileb://${path.module}/../auth/auth-lambda.zip \
          --region ${var.aws_region}
        echo "✅ Lambda Auth actualizado"
      else
        echo "  → Función no existe aún, se creará con terraform"
      fi
    EOT
  }

  depends_on = [
    null_resource.package_lambda_auth,
    aws_lambda_function.auth,
    aws_iam_role.lambda
  ]
}

resource "null_resource" "deploy_lambda_api" {
  triggers = {
    package_hash = filesha256("${path.module}/../api/api-lambda.zip")
    function_name = aws_lambda_function.api.function_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "📤 Subiendo Lambda API a AWS..."
      if aws lambda get-function --function-name ${aws_lambda_function.api.function_name} --region ${var.aws_region} &>/dev/null; then
        echo "  → Actualizando función existente..."
        aws lambda update-function-code \
          --function-name ${aws_lambda_function.api.function_name} \
          --zip-file fileb://${path.module}/../api/api-lambda.zip \
          --region ${var.aws_region}
        echo "✅ Lambda API actualizado"
      else
        echo "  → Función no existe aún, se creará con terraform"
      fi
    EOT
  }

  depends_on = [
    null_resource.package_lambda_api,
    aws_lambda_function.api,
    aws_iam_role.lambda
  ]
}

# ============================================
# Compilar y Desplegar Frontend
# ============================================

resource "null_resource" "build_frontend" {
  triggers = {
    # Triggers cuando cambian archivos del frontend
    source_hash = sha256(join("", [
      for f in fileset("${path.module}/../frontend/src", "**/*.{ts,html,scss,css}") : filesha256("${path.module}/../frontend/src/${f}")
    ]))
    package_json_hash = filesha256("${path.module}/../frontend/package.json")
    env_js_hash = filesha256("${path.module}/../frontend/src/assets/env.js")
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/../frontend
      
      # Verificar que npm esté instalado
      if ! command -v npm &> /dev/null; then
        echo "❌ npm no está instalado. Por favor instala Node.js"
        exit 1
      fi
      
      # Instalar dependencias si no existen
      if [ ! -d "node_modules" ]; then
        echo "📦 Instalando dependencias de npm..."
        npm install
      fi
      
      # Actualizar env.js con la URL del API Gateway
      API_URL="${aws_apigatewayv2_api.api_gateway.api_endpoint}"
      cat > src/assets/env.js <<ENVJS
window.__env = window.__env || {};

(function () {
    const hostname = window.location.hostname;
    const protocol = window.location.protocol;
    const port = window.location.port;

    if (hostname === 'localhost' && (port === '4200' || port === '4201')) {
        window.__env.API_URL = 'http://localhost:8000';
        window.__env.AUTH_URL = 'http://localhost:8001';
        console.log('🔧 Development mode: Using localhost');
    }
    else if (hostname.includes('cloudfront.net') || 
             hostname.includes('s3-website') || 
             hostname.includes('amazonaws.com')) {
        const API_GATEWAY_URL = '${aws_apigatewayv2_api.api_gateway.api_endpoint}';
        window.__env.API_URL = API_GATEWAY_URL + '/api';
        window.__env.AUTH_URL = API_GATEWAY_URL + '/auth';
        console.log('☁️ AWS Serverless mode: Using API Gateway', API_GATEWAY_URL);
    }
    else {
        const baseUrl = protocol + '//' + hostname + (port ? ':' + port : '');
        window.__env.API_URL = baseUrl + '/api';
        window.__env.AUTH_URL = baseUrl + '/auth';
        console.log('☸️ Kubernetes mode: Using Ingress paths', baseUrl);
    }
})();
ENVJS
      
      # Compilar para producción
      echo "🔨 Compilando frontend para producción..."
      npm run build -- --configuration production || npm run build
      
      # Verificar que se creó la carpeta dist
      if [ ! -d "dist" ]; then
        echo "❌ Error: No se creó la carpeta dist después de compilar"
        exit 1
      fi
      
      echo "✅ Frontend compilado exitosamente"
    EOT
  }

  depends_on = [
    aws_apigatewayv2_api.api_gateway,
    aws_s3_bucket.frontend
  ]
}

resource "null_resource" "deploy_frontend" {
  triggers = {
    # Usar el ID del build en lugar de calcular hash de dist/ (que puede no existir durante plan)
    build_id = null_resource.build_frontend.id
    bucket_name = aws_s3_bucket.frontend.bucket
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/../frontend
      
      # Encontrar la carpeta compilada
      DIST_DIR=""
      if [ -d "dist/explora" ]; then
        DIST_DIR="dist/explora"
      elif [ -d "dist/colombia-explora" ]; then
        DIST_DIR="dist/colombia-explora"
      elif [ -d "dist" ]; then
        DIST_DIR="dist"
      else
        echo "❌ Error: No se encontró la carpeta dist compilada"
        exit 1
      fi
      
      echo "📤 Subiendo frontend a S3: ${aws_s3_bucket.frontend.bucket}"
      echo "📁 Carpeta: $DIST_DIR"
      
      # Subir archivos a S3
      aws s3 sync "$DIST_DIR" s3://${aws_s3_bucket.frontend.bucket} \
        --delete \
        --region ${var.aws_region} \
        --cache-control "public, max-age=31536000, immutable" \
        --exclude "*.html" \
        --exclude "*.json"
      
      # Subir HTML y JSON con cache diferente
      aws s3 sync "$DIST_DIR" s3://${aws_s3_bucket.frontend.bucket} \
        --region ${var.aws_region} \
        --cache-control "public, max-age=0, must-revalidate" \
        --include "*.html" \
        --include "*.json"
      
      echo "✅ Frontend subido exitosamente"
    EOT
  }

  depends_on = [
    null_resource.build_frontend,
    aws_s3_bucket.frontend,
    aws_s3_bucket_website_configuration.frontend,
    aws_s3_bucket_policy.frontend
  ]
}

# ============================================
# Invalidar CloudFront Cache (si está habilitado)
# ============================================

resource "null_resource" "invalidate_cloudfront" {
  count = var.enable_cloudfront ? 1 : 0

  triggers = {
    frontend_deploy = null_resource.deploy_frontend.id
    distribution_id = aws_cloudfront_distribution.frontend[0].id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "🔄 Invalidando cache de CloudFront..."
      aws cloudfront create-invalidation \
        --distribution-id ${aws_cloudfront_distribution.frontend[0].id} \
        --paths "/*" \
        --region ${var.aws_region} || echo "⚠️  No se pudo invalidar cache (puede tardar unos minutos)"
      
      echo "✅ Cache invalidation iniciada"
    EOT
  }

  depends_on = [
    null_resource.deploy_frontend,
    aws_cloudfront_distribution.frontend
  ]
}

