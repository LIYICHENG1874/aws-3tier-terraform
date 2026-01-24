# Design Notes（設計ノート）
AWS 3-Tier Network Infrastructure via Terraform

---

## Summary（結論）
本プロジェクトでは、AWS における標準的な 3 層構成（Public / Private / Isolated）を Terraform で再現性高く構築しました。  
ALB → EC2 → RDS の通信のみを Security Group 参照で段階的に許可し、**最小権限とネットワーク境界の明確化**を重視しています。  
また、変数化・Outputs・機密情報分離などにより、**運用・拡張を見据えた IaC 設計**を意識しました。

---

## 1. Design Goals（設計目的・優先順位）
本プロジェクトの目的は、機能を網羅することではなく、  
**Cloud Engineer（クラウド構築）に求められる基礎設計力を明確に示すこと**です。

設計上の優先順位は以下の通りです。

1. **ネットワーク境界の分離（Public / Private / Isolated）**  
2. **最小権限（ALB → EC2 → RDS のみ許可）**  
3. **Terraform による再現性（誰が実行しても同じ構成）**  
4. **過度に複雑化せず、拡張余地を残す設計**

想定ユースケースは、**中小規模 Web アプリ / 社内業務システム / クラウド移行初期フェーズ**です。

---

## 2. Architecture Overview（構成方針）
### 2.1 Subnet Design（責務分離）
VPC 内に以下 3 種類のサブネットを定義し、責務を明確に分離しています。

- **Public Subnets**  
  - 外部公開が必要な **ALB のみ**を配置  
  - Internet Gateway へのルートを保持  

- **Private Subnets（Application）**  
  - **EC2（Auto Scaling Group）** を配置  
  - Public IP を付与せず、外部からの直接アクセスを遮断  
  - アウトバウンド通信は NAT Gateway 経由に限定  

- **Isolated Subnets（Database）**  
  - **RDS 専用サブネット**  
  - IGW / NAT へのルートを持たない（ネットワーク的に完全隔離）

「どこに何を置くか」だけでなく、  
**どの通信を成立させ、どれを遮断するか（境界設計）** を重視しています。

---

## 3. Security Design（セキュリティ設計）
### 3.1 Least Privilege via SG Reference（最小権限設計）
Security Group は CIDR ベースではなく、  
**Security Group 間の参照**によって通信を制御しています。

- **ALB Security Group**  
  - `0.0.0.0/0` → HTTP(80) を許可  

- **EC2 Security Group**  
  - ALB SG からの HTTP(80) のみ許可  

- **RDS Security Group**  
  - EC2 SG からの MySQL(3306) のみ許可  

上記以外の通信はすべて遮断されます。  
通信経路が明確になり、将来的な拡張や見直しも容易な構成です。

---

### 3.2 DB Isolation（DB を分離配置する理由）
RDS は外部通信を必要としないため、**Isolated Subnet に配置**しています。

- 不要な経路から DB を隔離し、攻撃対象領域を最小化  
- Private 側の誤設定があっても、ネットワーク境界で DB を保護可能  
- 「DB はアプリ層からのみ到達できる」という設計意図を明確化

---

### 3.3 RDS Configuration（検証用途としての割り切り）
本プロジェクトは検証用途のため、コストと構成簡素化を優先し  
RDS は **Single-AZ 構成**としています。

本番環境では可用性要件に応じて **Multi-AZ 有効化**を前提とします。

また、検証用途として  
`skip_final_snapshot = true` を設定していますが、  
本番ではデータ保護の観点から Final Snapshot を有効化する想定です。

---

## 4. Availability & Compute（可用性・コンピュート設計）
### 4.1 ALB + ASG（Multi-AZ 前提構成）
- ALB：複数 AZ の Public Subnet に配置  
- EC2：複数 AZ の Private Subnet に配置（ASG 管理）  
- ALB Target Group と ASG を連携  

本プロジェクトでは `desired_capacity = 1` としていますが、  
構成としては **スケールアウトや AZ 障害耐性を考慮できる形**になっています。

---

### 4.2 Launch Template & User Data（自動化）
- Launch Template により EC2 設定を統一  
- `user_data` による初期設定の自動化  
- AMI は data source を利用し、最新の Amazon Linux 2023 を取得  

手動作業を排除し、**再現性と一貫性**を重視しています。

---

## 5. IaC Design（Terraform 設計）
### 5.1 Parameterization & Secrets（変数化と機密情報管理）
環境差分や再利用性を考慮し、以下を `variables.tf` で変数化しています。

- AWS Region  
- VPC CIDR  
- EC2 Instance Type  
- DB Password（`sensitive = true`）
- Project Name（リソース命名・タグ付け用）

機密情報は Git 管理対象外とし、ログ露出も防ぐ前提としています。

---

### 5.2 Remote State（将来導入前提として理解）
チーム運用を前提とする場合、  
S3 + DynamoDB による Remote Backend が有効であると理解しています。

本プロジェクトでは構成をシンプルに保つため未導入ですが、  
state 共有・ロックの必要性は理解しています。

---

## 6. Validation（動作確認）
構築後、AWS マネジメントコンソール上で各リソースの状態を確認し、  
想定通りに構成・通信が成立していることを検証しました。

- `terraform apply` により全リソースが正常に作成されたことを確認  
- ALB Target Group のヘルスチェックおよびレスポンスを確認し、ALB → EC2 の疎通が成立していることを確認  
- RDS のステータスおよび接続情報を確認し、EC2 → RDS 間の接続が成立していることを確認  
- 想定外経路（Internet → EC2 直アクセス / 外部 → RDS）が Security Group により遮断されていることを確認  
- Private Subnet からのアウトバウンド通信が NAT Gateway 経由で行われていることを確認

---

## 7. Trade-offs（設計判断と割り切り）
本プロジェクトでは  
**「正しさ」＞「網羅性」＞「最適化」** の順で優先しています。

- **可読性優先**  
  - Terraform Module 分割は未実施  
  - 環境分割（dev/stg/prod）やリソース増加が必要になった段階で module 化する想定  

- **標準構成優先**  
  - NAT Instance ではなく NAT Gateway を採用  
  - コストより運用負荷・安定性を重視  

- **学習フェーズとしての割り切り**  
  - 監視 / WAF / CI/CD などは次フェーズの課題として切り分け  

---

## 8. Out of Scope（スコープ外の位置づけ）
本プロジェクトでは、以下の領域は意図的に扱っていません。

- CI/CD パイプライン設計  
- 監視・アラート・ログ集約の高度設計  
- マルチアカウント構成（AWS Organizations）  
- マルチリージョン DR  

ただし、これらは本プロジェクトのスコープ外とし、
設計上は拡張可能な前提として整理しています。

---

## 9. Summary（まとめ）
- 3 層構成（Public / Private / Isolated）の責務分離  
- SG 参照による最小権限設計（ALB → EC2 → RDS）  
- Terraform による再現性・保守性（変数化 / 自動化 / 機密分離）  

本番要件に応じて Multi-AZ、Remote State、監視、HTTPS/WAF などへ  
段階的に拡張できる土台構成となっています。
