# Lambda para Desligar Instâncias EC2

Este projeto utiliza AWS Lambda e Terraform para criar uma função Lambda que desliga uma instância EC2 em um horário específico todos os dias. Isso é alcançado usando AWS CloudWatch EventBridge para agendar a execução da função Lambda.

## Pré-requisitos

Antes de começar, certifique-se de ter os seguintes pré-requisitos:

- Conta na AWS
- Terraform instalado localmente
- Permissões adequadas para criar recursos AWS como Lambda, IAM Role, CloudWatch EventBridge, e EC2

## Estrutura do Projeto

O projeto é estruturado da seguinte forma:

├── lambda_function.py # Código da função Lambda
├── main.tf # Configuração do Terraform
├── variables.tf # Variáveis do Terraform
└── README.md # Este arquivo