
# 📦 Projeto Pokedex – DevOps e Integração Contínua

## 📖 Visão Geral

O **Projeto Pokedex** é uma aplicação moderna em **React + Vite**, com integração de serviços em **AWS (Terraform + Lambda)**, conteinerização com **Docker**, pipelines de **CI/CD no GitHub Actions** e monitoramento de eventos via **Discord Webhook**.

Este repositório foi criado para estudos e prática de **DevOps**, cobrindo desde o desenvolvimento até o deploy automatizado.

---

## 🛠 Tecnologias Utilizadas

* **Frontend**: React 19 + Vite + Chakra UI + Styled Components
* **Infraestrutura como Código (IaC)**: Terraform
* **Funções Serverless**: AWS Lambda (Python)
* **Testes**: Vitest (unitários), Cypress (E2E)
* **CI/CD**: GitHub Actions
* **Qualidade de código**: ESLint, Husky, Lint-staged
* **Containerização**: Docker
* **Integração/Alertas**: Discord Webhook

---

## 🏛️ Arquitetura

```
projeto-pokedex/
│
├── src/                  # Código React
├── tests/                # Testes unitários e de integração
├── infra/                # Arquivos Terraform
│   ├── main.tf
│   └── variables.tf
│
├── lambda/               # Funções AWS Lambda
│   └── index.py
│
├── .github/workflows/    # Pipelines GitHub Actions
│   ├── ci-cd.yml
│   └── pr-check.yml
│
├── Dockerfile            # Docker para dev
├── Dockerfile.prod       # Docker para produção
├── package.json          # Dependências e scripts
└── README.md             # Documentação
```

---

## 🚀 Instalação e Execução

### 1️⃣ Pré-requisitos

* Node.js >= 18
* Docker
* Conta AWS configurada (para deploy da infraestrutura)

### 2️⃣ Instalar dependências

```bash
npm install
```

### 3️⃣ Executar em desenvolvimento

```bash
npm run dev
```

Acesse em: [http://localhost:5173](http://localhost:5173)

### 4️⃣ Executar testes

* **Unitários**:

```bash
npm run test
```

* **Cobertura**:

```bash
npm run test:coverage
```

* **E2E (Cypress)**:

```bash
npm run test:e2e
```

---

## ⚙️ CI/CD

O projeto conta com pipelines configurados no **GitHub Actions**:

* **PR Check (`pr-check.yml`)**

  * Linter (ESLint)
  * Testes unitários (Vitest)

* **CI/CD (`ci-cd.yml`)**

  * Build da aplicação
  * Testes
  * Deploy da infraestrutura (Terraform)
  * Deploy da Lambda no AWS
  * Notificação via **Discord Webhook**

---

## 🌐 Deploy

O deploy é feito via **Terraform** para a AWS.

### Exemplos de comandos:

```bash
cd infra
terraform init
terraform plan
terraform apply
```

---

## 📡 Lambda + Discord

A Lambda (`index.py`) recebe eventos da AWS e envia notificações para um canal do **Discord** usando Webhooks.

Exemplo de mensagem:

```
🚀 Evento DevOps detectado: CodeBuild  
Detalhes: { ... }
```

---

## 🔍 Qualidade de Código

O projeto utiliza:

* **ESLint** (checagem de estilo e boas práticas)
* **Husky + Lint-staged** (verificações automáticas em commits)

Rodar manualmente:

```bash
npm run lint
npm run lint:fix
```

---

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas alterações (`git commit -m "feat: nova funcionalidade"`)
4. Envie (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request 🚀

---

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).
