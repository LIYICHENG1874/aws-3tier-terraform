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
  - DB Isolated (2AZ): RDS 用（インバウンドのみ）

- **Compute**
  - Launch Template + Auto Scaling Group (t3.micro)

- **Database**
  - Amazon RDS MySQL
  - Multi-AZ 対応可能な構成

---
## 7. 実装のポイント / Implementation Highlights

本プロジェクトでは、Cloud Engineer（構築）ポジションに求められる  
基礎的な構成要素を正しく実装することを重視しています。

### Infrastructure as Code (IaC)

- Terraform によるリソース管理
- 最新 AMI の動的取得（data source）
- user_data による EC2 初期設定の自動化
- 構成変更の再現性と管理性の確保

### セキュリティ設計

- ALB → EC2 → RDS の段階的な通信制御
- DB サブネットのネットワークレベルでの隔離

### 高可用性

- Multi-AZ 構成（ap-northeast-1a / 1c）
- ALB + Auto Scaling Group による冗長化構成

### 補足

- 本デモは検証目的のため Auto Scaling Group の desired_capacity を 1 としていますが、  
  実運用ではスケールアウト可能な構成です。
---


## 8. セットアップ方法 / Usage

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

- CI/CD パイプライン（GitHub Actions + Terraform）
- AWS Organizations を用いたマルチアカウント構成

