# Design Notes 
AWS 3-Tier Architecture via Terraform

---

## 1. 設計目的（Design Goals）

本プロジェクトは、機能の網羅性を目的としたものではなく、  
**Cloud Engineer（クラウド構築）ポジションに求められる基礎設計力を、正しく・明確に示すこと**を目的としています。

主な設計目標は以下の通りです。

- AWS Best Practices に沿った **標準的な 3 層アーキテクチャ** の構築  
- Public / Private / Isolated の **ネットワーク境界を明確に分離**
- Terraform による **再現性・保守性・可読性** のある IaC 実装
- 過度な複雑化を避けつつ、**セキュリティ・可用性・拡張性** への配慮を示す

本構成は **中小規模の Web アプリケーションや社内業務システムを想定した構成** です。

---

## 2. ネットワーク設計の考え方（Network Design Rationale）

### 2.1 サブネット構成の方針

VPC 内では、役割が明確に分かれた 3 種類のサブネットを定義しています。

- **Public Subnets**
  - 外部公開が必要な ALB のみを配置
  - Internet Gateway へのルートを保持

- **Private Subnets**
  - EC2（Application Layer）を配置
  - パブリック IP を持たず、  
    アウトバウンド通信は NAT Gateway 経由に限定

- **DB Isolated Subnets**
  - RDS 専用サブネット
  - Internet Gateway / NAT Gateway へのルートを持たない
  - ネットワークレベルで完全に分離

各レイヤの責務を明確にし、  
**必要最小限の通信のみを許可する構成**としています。

---

### 2.2 NAT Gateway を採用した理由

Private Subnet からのアウトバウンド通信には **NAT Gateway** を使用しています。

主な理由は以下の通りです。

- AWS マネージドサービスであり、運用負荷が低い
- 高可用性が担保されており、単一障害点を避けられる
- クラウド移行初期の構成として一般的である

NAT Instance と比較するとコストは高くなりますが、  
本プロジェクトでは **安定性と標準構成の理解を優先**しました。

---

## 3. セキュリティ設計（Security Design）

### 3.1 Security Group の段階的制御

Security Group は CIDR ベースではなく、  
**Security Group 間の参照**によって通信を制御しています。

- **ALB Security Group**
  - `0.0.0.0/0` からの HTTP（80）を許可

- **EC2 Security Group**
  - ALB Security Group からの HTTP（80）のみを許可

- **RDS Security Group**
  - EC2 Security Group からの MySQL（3306）のみを許可

通信経路が明確になり、  
後続のルール追加や見直しも容易な構成です。

---

### 3.2 DB のネットワーク隔離

RDS は **Isolated Subnet** に配置しています。

- DB 自体が外部通信を必要としない
- Private Subnet 側の誤設定があっても、  
  ネットワークレベルで DB を保護できる
- 「DB は最終防衛ライン」という設計思想を明確にするため

---

## 4. Compute / 可用性設計（Availability）

### 4.1 ALB + Auto Scaling Group 構成

- ALB は複数 AZ の Public Subnet に配置
- EC2 は複数 AZ の Private Subnet に配置
- ALB Target Group と ASG を連携

本デモでは `desired_capacity = 1` としていますが、  
構成上は **スケールアウトおよび AZ 障害耐性を考慮した設計**です。

---

### 4.2 Launch Template と User Data

- Launch Template により EC2 設定を統一
- `user_data` による初期設定の自動化
- AMI は data source を使用し、最新の Amazon Linux 2023 を取得

手動作業を排除し、  
**自動化と環境の一貫性**を重視しています。

---

## 5. Infrastructure as Code の設計判断

### 5.1 パラメータ化

以下の要素を `variables.tf` により変数化しています。

- AWS Region  
- VPC CIDR  
- EC2 Instance Type  
- DB Password（`sensitive = true`）

環境差分への対応と、  
機密情報のログ露出防止を意識しています。

---

### 5.2 Remote State（本プロジェクト外だが考慮済み）

`provider.tf` 内に、  
S3 + DynamoDB を用いた Remote Backend の例をコメントとして記載しています。

- チーム開発時の state 共有・ロックを理解していることを示すため
- 本デモでは構成をシンプルに保つため未導入

---

## 6. トレードオフ（Trade-offs）

本設計では以下のような判断を行っています。

- **可読性を優先**
  - Terraform Module への分割は行っていない
- **構成の正しさを優先**
  - WAF、監視、CI/CD 等は未実装
- **安定性を優先**
  - NAT Gateway を採用（コスト最優先ではない）

---

## 7. スコープ外（Out of Scope）

本プロジェクトでは以下は対象外としています。

- CI/CD パイプライン
- マルチアカウント構成（Organizations）
- 監視・アラート・ログ集約
- マルチリージョン災害対策

これらは将来的な拡張項目と位置付けています。

---

## 8. まとめ（Summary）

本プロジェクトは以下を示すことを目的としています。

- AWS における基本的なネットワーク / 3 層構成の理解
- セキュリティ境界と責務分離への配慮
- Terraform を用いた構築・管理の基礎力

唯一の正解を示すものではなく、  
**実務で十分に受け入れられる現実的な構成**を意識しています。
