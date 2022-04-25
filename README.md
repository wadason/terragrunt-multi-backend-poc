# terragrunt-multi-backend-poc

一般的にパフォーマンスの観点や、障害の影響範囲を最小限にするためにstateを分離するパターンはよく知られている。
もちろん上記観点でも分離したいが、

- 複数のメンバーが同一のインフラリポジトリを扱う
- 新規のインフラ構築や日を跨いだ検証を行いたい（が、terraformで実装はしたい)

といったケースに直面した。
stateを意味のある塊ごとに管理することで、一元管理していた時よりも作業のコンフリクトの発生頻度を少なくし、
remoteでのstate管理およびlockは担保したままにする方法を検証。
複数のbackendの設定をDRYにしたかったので、[terragrunt](https://terragrunt.gruntwork.io/)を利用する。

## 前提

- AWSを利用。
- 一つのAWSアカウントに、複数のマイクロサービスが管理されていることを想定。
  - `terraform/stg/main/service-*`単位でそれぞれ責務を持ち、インフラ的には依存関係がほとんどない。
- `modules/common`配下は、それぞれの環境から呼び出されることを想定。
  - これにより環境の差異を解消している
- backendにはS3とDynamoDBを用いる。[cloudposse/terraform-aws-tfstate-backend](https://github.com/cloudposse/terraform-aws-tfstate-backend)を利用。

## 複数のremote state

`terragrunt.hcl`を親ディレクトリと子ディレクトリに配置する。

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "YOUR_S3_BUCKET"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "REGION"
    encrypt        = true
    dynamodb_table = "YOUR_DYNAMO_DB_TABLE"
  }
}
```

remote stateがバケット内にserviceごとに作成されている。
```bash
$ aws s3 ls s3://YOUR_S3_BUCKET
PRE service-a/
PRE service-b/

$ aws s3 ls s3://poc-stg-terraform-state/service-a/
2022-04-22 14:58:49        969 terraform.tfstate
```

それぞれのbackendごとにlockが管理できている。
```bash
$ aws dynamodb scan --table-name YOUR_DYNAMO_DB_TABLE
```

```json
{
    "Items": [
        {
            "Digest": {
                "S": "xxxxxxxxxxx"
            },
            "LockID": {
                "S": "YOUR_S3_BUCKET/service-b/terraform.tfstate-md5"
            }
        },
        {
            "Digest": {
                "S": "xxxxxxxxxxx"
            },
            "LockID": {
                "S": "YOUR_S3_BUCKET/service-a/terraform.tfstate-md5"
            }
        }
    ],
    "Count": 2,
    "ScannedCount": 2,
    "ConsumedCapacity": null
}
```

## 別のstateのリソースを参照したい場合

terragruntの機能を用いて`inputs`で渡すことができるが、`dependency`が必要となる。
全てのパターンで汎用的に利用できるかは怪しいので、[Data Sources](https://www.terraform.io/language/data-sources)を用いる。

ref : https://terragrunt.gruntwork.io/docs/rfc/imports/

## terragruntによる操作

```bash
# 全体
$ terragrunt run-all init/plan/apply

# 個別
$ terragrunt run-all init/plan/apply --terragrunt-include-dir "service-a"   
```

stateの操作も可能。
```bash
$ terragrunt run-all state list
$ terragrunt run-all state rm XXXX
$ terragrunt run-all state mv XXXX XXXX
```
