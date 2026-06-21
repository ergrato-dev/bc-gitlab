# 03 — GitLab Package Registry

GitLab Package Registry soporta multiples formatos de paquetes nativamente. Cada proyecto tiene su propio espacio de paquetes en Deploy → Package Registry.

## npm Registry

### Configuracion del proyecto (`.npmrc`):
```
@mi-org:registry=https://gitlab.example.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/
//gitlab.example.com/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}
```

### Pipeline npm:
```yaml
publish-npm:
  stage: deploy
  image: node:18-alpine
  script:
    - echo "@mi-org:registry=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/" > .npmrc
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}" >> .npmrc
    - npm publish
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

## Maven Repository

### Pipeline Maven:
```yaml
publish-maven:
  stage: deploy
  image: maven:3.9-eclipse-temurin-17
  script:
    - |
      mvn deploy -s ci_settings.xml \
        -DaltDeploymentRepository=gitlab::default::${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven
  rules:
    - if: $CI_COMMIT_TAG
```

### ci_settings.xml:
```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Job-Token</name>
            <value>${CI_JOB_TOKEN}</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```

## PyPI Repository

### Pipeline Python:
```yaml
publish-pypi:
  stage: deploy
  image: python:3.11-slim
  script:
    - pip install build twine
    - python -m build
    - TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token python -m twine upload
      --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
```

## Otros formatos soportados
- **NuGet**: Para paquetes .NET
- **Conan**: Paquetes C/C++
- **Composer**: Dependencias PHP
- **Helm**: Charts de Kubernetes
- **Generic**: Archivos arbitrarios (via API)
- **Terraform Module Registry**: Modulos de Terraform
