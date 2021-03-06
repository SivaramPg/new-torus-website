
#!/bin/bash
git clone git@github.com:torusresearch/torus-serverless.git ~/torus-serverless
PACKAGE_VERSION=$(cat package.json | grep '"version"' | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d ' ')
FOLDER=''
if [[ "$GITHUB_REF" = 'refs/heads/master' ]]; then
  FOLDER='cloudfront-redirect'
  FUNCTION_NAME='torus-routing'
  CLOUDFRONTID=$CLOUDFRONT_DISTRIBUTION_ID
elif [[ "$GITHUB_REF" = 'refs/heads/binance' ]]; then
  FOLDER='cloudfront-binance-redirect'
  FUNCTION_NAME='torus-binance-routing'
  CLOUDFRONTID=$CLOUDFRONT_BINANCE_DISTRIBUTION_ID
fi
cd ~/torus-serverless/$FOLDER
sed -i -e "s|const GLOBAL_VERSION.*|const GLOBAL_VERSION = \"v$PACKAGE_VERSION\";|g" index.js
git config user.email "no-reply@tor.us"
git config user.name "torus-bot"
git diff --quiet && git diff --staged --quiet || (git commit -am "Updating version" && git push origin master)
zip lambda-code index.js
aws --no-paginate lambda update-function-code --function-name $FUNCTION_NAME --publish --zip-file "fileb://lambda-code.zip"
aws --no-paginate cloudfront get-distribution-config --id $CLOUDFRONTID > cf_config.json
ETAG=$(cat cf_config.json | grep ETag | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g')
sleep 10
node "$GITHUB_WORKSPACE/scripts/createUpdatedDistributionConfig.js"
aws --no-paginate cloudfront update-distribution --distribution-config "file://updated_cf_config.json" --id $CLOUDFRONTID --if-match "$ETAG"
aws --no-paginate cloudfront create-invalidation --distribution-id $CLOUDFRONTID --paths "/*"
cd $GITHUB_WORKSPACE