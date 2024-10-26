#!bin/bash

# 1. 関数名を取得してスペース区切りの文字列として保存
# Azure CLI だと、StagingSlotの関数一覧を取得することができないので、REST APIを使う
# https://stackoverflow.com/questions/75801784/how-can-i-list-azure-functionapp-functions-in-a-specific-deployment-slot-with-az
FUNCTIONS=$(az rest --method get --uri "https://management.azure.com/subscriptions/ba29533e-1e4c-43a8-898a-a5815e9b577b/resourceGroups/tatsukoni-test-v2/providers/Microsoft.Web/sites/func-tatsukoni-test-v1/slots/staging/functions?api-version=2018-11-01" | \
jq -r '.value[] | select(all(.properties.config.bindings[].type; . != "httpTrigger")) | .properties.name')

if [ -n "$FUNCTIONS" ]; then
  # 2. 関数名を使ってアプリケーション設定の文字列を構築
  SETTINGS=$(echo "$FUNCTIONS" | while read -r func; do
    echo "AzureWebJobs.${func}.Disabled=true "
  done)
  SETTINGS=$(echo $SETTINGS | sed -e 's/[[:space:]]*$//')

  # 3. Staging SlotのHttpTriggger以外の関数を無効化する
  az functionapp config appsettings set \
    --name func-tatsukoni-test-v1 \
    --resource-group tatsukoni-test-v2 \
    --slot staging \
    --slot-settings $SETTINGS
fi
