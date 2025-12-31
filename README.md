# AWS 3-Tier Network Infrastructure via Terraform

## 1. 概要 / Project Overview

本プロジェクトは、AWS のベストプラクティスに基づき、高可用性とセキュリティを担保した  
**標準的な 3 層アーキテクチャ（Web / App / DB）** を Terraform により自動構築したものです。

通信専攻のバックグラウンドを活かし、ネットワークの分離設計およびアクセス制御（最小権限）の明確化に重点を置いて、設計・実装しました。

---

## 2. アーキテクチャ / Architecture

![Architecture](architecture.png)

### レイヤ構成

- **Public Layer**
  - Application Load Balancer（ALB）を配置
  - 外部からの HTTP リクエストを受信

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
## 想定ユースケース / Target Use Case

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

---

## 5. IaC 工程化の実装 / Engineering Excellence

単なるリソース構築に留まらず、実務でのメンテナンス性と安全性を意識した設計を取り入れています。

- **パラメータ化による柔軟性 (`variables.tf`)** リージョン、CIDR、インスタンスタイプなどを変数化し、環境の再利用性と可読性を向上。
- **機密情報の保護 (`sensitive` 変数)** DBパスワード等の機密情報は `sensitive = true` として定義。コード内へのハードコーディングを排除し、コンソール出力やログへの露出を防止。
- **チーム開発の考慮 (Backend 構成)** チームでの状態共有とロックを想定し、S3/DynamoDB を使用した Remote Backend の構成案をコード内にコメントとして記述。
- **デリバリの効率化 (`outputs.tf`)** 構築完了後、ALB の DNS エンドポイント等を自動出力。手動での確認作業を減らし、後続のタスクへスムーズに連携。

---

## 6. 設計のポイント / Key Features & Security

本プロジェクトでは、Cloud Engineer（構築）ポジションに求められる  
**「基礎構成を正しく実装できること」** を重視しました。

### Infrastructure as Code (IaC)

- すべてのリソースを Terraform でコード化
- data ソースを用いた最新 AMI の動的取得
- user_data による EC2 初期設定の自動化
- 環境構築の再現性と変更管理性を確保

### セキュリティ設計（最小権限の原則）

- **Security Group の段階的制御**
  - ALB → EC2 → RDS のみ通信を許可
  - 不要なポート・CIDR の開放を排除

- **DB の完全隔離**
  - DB 用サブネットは NAT Gateway を持たず、外部通信不可
  - インフラ構成レベルでのデータ保護を実現

### 高可用性（High Availability）

- **Multi-AZ 構成**
  - ap-northeast-1a / 1c にサブネットを分散
  - ALB + ASG により AZ 障害時もサービス継続可能な構成

### 設計上の考慮点

- **コストを意識した構成**  
  本デモでは検証目的のため Auto Scaling Group の desired_capacity を 1 に設定していますが、実運用では容易にスケールアウト可能な構成です。

---

## 7. 設計判断 / Design Decisions

- **なぜ DB を Isolated Subnet に配置したか**  
  DB は外部通信を必要としないため、NAT Gateway へのルートを持たないサブネットに配置し、  
  ネットワークレベルで攻撃対象領域を最小化しました。

- **なぜ Terraform を採用したか**  
  環境構築の再現性と変更履歴管理を重視し、Infrastructure as Code による構築を行いました。

---

## 8. リソース構成 / Resource Components

- **VPC**: 10.0.0.0/16  

- **Subnets**
  - Public (2AZ): ALB 用
  - Private (2AZ): EC2 用（NAT Gateway 経由でアウトバウンド可）
  - DB Isolated (2AZ): RDS 用（インバウンドのみ）

- **Compute**
  - Launch Template + Auto Scaling Group (t3.micro)

- **Database**
  - Amazon RDS MySQL
  - Multi-AZ 対応可能な構成

---

## 9. セットアップ方法 / Usage

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
## 10. スコープについて / Scope

※ 本プロジェクトは Cloud Engineer（構築）ポジションを想定した基礎構成であり、  
CI/CD、マルチアカウント管理、運用自動化などの高度な運用設計については、
本プロジェクトでは対象外とし、今後の発展的な課題としています。

---

## 11. 今後の拡張案 / Future Work（Optional）

- CI/CD パイプライン（GitHub Actions + Terraform）
- AWS Organizations を用いたマルチアカウント構成

