# GitHub Actions OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # GitHub's OIDC thumbprint (per AWS docs)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
  ]
}


# Allow GitHub Actions from a specific repo/branch to assume this role
data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    # audience must be sts.amazonaws.com
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # allow this role to be assumed from *this* repo:
    #  - any branch push:  repo:mimznumb/go-ethereum:ref:refs/heads/*
    #  - pull_request workflows: repo:mimznumb/go-ethereum:pull_request
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:mimznumb/go-ethereum:ref:refs/heads/*",
        "repo:mimznumb/go-ethereum:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "github_eks_deploy" {
  name               = "github-eks-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}




data "aws_iam_policy_document" "github_eks_policy" {
  statement {
    sid    = "EksDescribe"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EcrRead"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_eks_inline" {
  role   = aws_iam_role.github_eks_deploy.id
  policy = data.aws_iam_policy_document.github_eks_policy.json
}
