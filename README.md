# AWS 3-Tier Network Infrastructure via Terraform

## 1. 概要 / Project Overview

本プロジェクトは、AWS のベストプラクティスに基づき、  
**Web / App / DB の各ロールを想定した標準的な 3 層ネットワーク構成**を  
Terraform により自動構築したものです。

各レイヤーは Public / Private / Isolated Subnet に明確に分離されており、  
通信専攻のバックグラウンドを活かして、  
ネットワーク境界設計および  
Security Group によるレイヤー間アクセス制御を重視して設計・実装しています。


なお、本構成はスケーラブルな 3 層アーキテクチャの**基盤設計**を目的としており、  
アプリケーション層の EC2 は検証用途として最小構成で構築しています。

---

## 2. アーキテクチャ / Architecture

![Architecture Diagram](docs/architecture.png)

### レイヤ構成

- **Public Layer**
  - Application Load Balancer（ALB）を配置
  - 外部からの HTTP リクエストを受信
  - Public Subnet には EC2 を配置せず、インターネットからの入口を ALB に集約

- **Private Layer**
  - EC2（Auto Scaling Group）を配置
  - インターネットからの直接アクセスを遮断
  - NAT Gateway 経由でのみアウトバウンド通信を許可

- **Isolated DB Layer**
  - RDS（MySQL）を配置
  - NAT Gateway へのルートを持たない完全隔離サブネット
  - ネットワークレベルでの攻撃対象領域を最小化

---

## 3. 想定ユースケース / Target Use Case

本構成は以下のような用途を想定しています。

- 中小規模 Web アプリケーション
- 社内業務システム（B2B）
- クラウド移行初期フェーズの標準構成

---

## 4. 技術スタック / Tech Stack

- **Cloud**: AWS  
- **IaC**: Terraform (v1.5.0+)  
- **Compute**: EC2 / Auto Scaling Group  
- **Load Balancer**: Application Load Balancer  
- **Database**: Amazon RDS (MySQL 8.0)  
- **OS**: Amazon Linux 2023  
- **Security**: Security Group によるレイヤー間アクセス制御

---

## 5. IaC 工程化の実装 / Engineering Excellence

本プロジェクトでは、Terraform を用いた Infrastructure as Code により、  
再現性・可読性・保守性を意識した構築を行っています。

- 主要な設定値（リージョン、CIDR、インスタンスタイプ等）の変数化
- 機密情報（DB パスワード）の安全な取り扱い
- チーム開発を想定した Remote State 構成の考慮
- Outputs を用いたデプロイ後の確認作業の効率化

設計判断の背景やトレードオフについては、  
`docs/design-notes.md` にて補足しています。

---


## 6. リソース構成 / Resource Components

- **VPC**: 10.0.0.0/16  

- **Subnets**
  - Public (2AZ): ALB 用
  - Private (2AZ): EC2 用（NAT Gateway 経由でアウトバウンド可）
  - DB Isolated (2AZ): RDS 用（アプリケーション層からのみインバウンド許可）

- **Compute**
  - Launch Template + Auto Scaling Group (t3.micro)


- **Database**
  - Amazon RDS（MySQL）
  - Isolated Subnet に配置し、アプリケーション層からのみアクセス可能

---
## 7. 実装のポイント / Implementation Highlights

本プロジェクトでは、Cloud Engineer（構築）ポジションに求められる  
基礎的な構成要素を正しく実装することを重視しています。

### Infrastructure as Code（IaC）

- Terraform によるリソース管理
- data source を利用した最新 AMI の動的取得
- user_data による EC2 初期設定の自動化
- 構成変更に対する再現性および管理性の確保

### セキュリティ設計

- ALB → EC2 → RDS の段階的な通信制御
- DB サブネットのネットワークレベルでの隔離

### 高可用性に向けた設計

- 複数 AZ（ap-northeast-1a / 1c）にまたがる Subnet 構成
- ALB および Auto Scaling Group を用いた冗長化を想定した設計

### 補足

- 本デモは検証目的のため Auto Scaling Group の `desired_capacity` を 1 としていますが、  
  実運用ではスケールアウト可能な構成としています。

---


## 8. セットアップ方法 / Usage

※ 事前に AWS 認証情報（AWS CLI / 環境変数など）の設定が必要です。
※ `db_password` は実行時に入力、または `terraform.tfvars` で指定してください  
（機密情報のため Git 管理対象外としています）。

```bash
# リポジトリのクローン
git clone <repository-url>

# 初期化
terraform init

# 実行計画の確認
terraform plan

# デプロイ
terraform apply

```
---
## 9. スコープについて / Scope

※ 本プロジェクトは Cloud Engineer（構築）ポジションを想定した基礎構成であり、  
CI/CD、マルチアカウント管理、運用自動化などの高度な運用設計については、
本プロジェクトでは対象外とし、今後の発展的な課題としています。

---

## 10. 今後の拡張案 / Future Work（Optional）

本構成をベースとして、以下のような発展的な取り組みを想定しています。

- GitHub Actions を用いた CI/CD パイプラインの導入
- AWS Organizations を活用したマルチアカウント構成への展開


