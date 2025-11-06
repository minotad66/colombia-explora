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
        const API_GATEWAY_URL = 'https://g9hafoviz0.execute-api.us-east-1.amazonaws.com';
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
