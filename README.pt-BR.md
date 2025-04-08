# FlyChain: Revolucionando a Venda de Passagens Aéreas com Blockchain

<i>🏆 Projeto vencedor desenvolvido para o Modular Carnival Hackathon, da Modular Crypto — Fevereiro de 2025.</i>
 
<img  align=center src="https://github.com/Cyber0Ulmo/HKT-AT-0V/blob/develop/Flychain.png?raw=true">

## Visão Geral

FlyChain (Contrato `FlightTicket.sol`) é uma solução inovadora que utiliza tecnologia blockchain para transformar o processo de venda e gerenciamento de passagens aéreas. Desenvolvido na rede Scroll, o projeto oferece uma plataforma transparente, eficiente e automatizada para passageiros e empresas aéreas.

## 🌍 Available Languages

- 🇺🇸 [English](README.md)
- 🇧🇷 [Português Brasileiro](README.pt-BR.md)

## Características Principais

### Para Passageiros
- **Reserva Direta**: Reserve assentos diretamente através do contrato inteligente.
- **Cancelamento Flexível**: Cancele passagens até uma hora antes do voo, com reembolso automático.
- **Gerenciamento de Saldo**: Deposite e retire fundos de sua conta no contrato.
- **Transparência Total**: Todas as transações são registradas na blockchain.

### Para Empresas Aéreas
- **Automação de Processos**: Redução significativa de custos operacionais.
- **Gestão Eficiente**: Controle total sobre voos, assentos e receitas.
- **Dados em Tempo Real**: Acesso imediato a informações sobre vendas e ocupação.

## Tecnologias Utilizadas

- **Solidity**: Linguagem de programação para contratos inteligentes.
- **ERC1155**: Padrão de token multi-ativos para representação de passagens.
- **Rede Scroll**: Oferece escalabilidade, baixo custo e alta velocidade de transações.

## Funcionalidades do Contrato Inteligente

### Gerenciamento de Voos
- `addFlight`: Permite que a empresa aérea adicione novos voos com detalhes completos.
- `getFlight`: Recupera informações detalhadas sobre um voo específico.

### Reserva de Assentos
- `bookSeat`: Permite que passageiros reservem assentos pagando com ether.
- `bookSeatUsingPassengerBalance`: Opção de reserva utilizando saldo pré-depositado.

### Cancelamento e Reembolso
- `cancelTicket`: Passageiros podem cancelar reservas e receber reembolso automático.

### Gerenciamento de Saldo
- `addPassengerBalance`: Passageiros podem adicionar saldo à sua conta.
- `claimPassengerBalance`: Permite a retirada do saldo acumulado.

### Funcionalidades para Empresas Aéreas
- `getFlightBalance`: Verifica o saldo acumulado para cada voo.
- `withdrawFlightFunds`: Permite a retirada de fundos após a partida do voo.

## Vantagens da Rede Scroll

- **Escalabilidade**: Suporta um grande volume de transações.
- **Baixo Custo**: Taxas de transação reduzidas.
- **Alta Velocidade**: Confirmações rápidas de transações.
- **Compatibilidade com Ethereum**: Facilita a integração com o ecossistema Ethereum.

## Roadmap de Desenvolvimento

### Fase 1: Personalização e Segurança
- Implementação de mapa de assentos interativo.
- Seleção múltipla de assentos.
- Sistema de blocklist para carteiras.
- Funcionalidade de cancelamento pela empresa aérea.

### Fase 2: Expansão de Funcionalidades
- Introdução de diferentes categorias de assento.
- Sistema de upgrades flexíveis.
- Integração de programa de fidelidade.
- Implementação de revenda de passagens.

### Fase 3: Integração e Parcerias
- Desenvolvimento de API para sistemas de reserva existentes.
- Estabelecimento de parcerias com seguradoras.
- Suporte a contratos multi-companhia.

### Fase 4: Inovações Avançadas
- Tokenização de serviços adicionais (refeições, bagagem extra).
- Implementação de sistema de compensação de carbono.
- Integração com protocolos DeFi para opções financeiras avançadas.

## Como Contribuir

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/NovaFuncionalidade`)
3. Faça commit das suas alterações (`git commit -m 'Adiciona nova funcionalidade'`)
4. Faça push para a branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

## Contato

Link original do Projeto: [https://github.com/Cyber0Ulmo/HKT-AT-0V](https://github.com/Cyber0Ulmo/HKT-AT-0V)

## Licença

Este projeto está licenciado sob a Licença MIT
