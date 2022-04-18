const fs = require('fs');

module.exports = async ({ github, context, core }) => {
  const gasUsage = getGasUsage();
  const commentBody = buildComment(gasUsage);

  const { data: comments } = await github.rest.issues.listComments({
    issue_number: context.issue.number,
    owner: context.repo.owner,
    repo: context.repo.repo
  });

  const botComment = comments.find(comment => comment.user.id === 41898282);

  if (botComment) {
    await github.rest.issues.updateComment({
      comment_id: botComment.id,
      owner: context.repo.owner,
      repo: context.repo.repo,
      body: commentBody
    });
  } else {
    await github.rest.issues.createComment({
      issue_number: context.issue.number,
      owner: context.repo.owner,
      repo: context.repo.repo,
      body: commentBody
    });
  }
}

function getGasUsage() {
  var gasUsage = {};
  fs.readdir("./gas_usage/", function (err, contractDirs) {
    if (err) {
      console.error("Error reading gas_usage dir:", err);
      return
    }

    contractDirs.forEach(function (contractDir, index) {
      console.log("Processing: " + contractDir);

      fs.readdir(`./gas_usage/${contractDir}`, function (err, files) {
        if (err) {
          console.error("Error reading " + contractDir, err);
          return
        }

        gasUsage[contractDir] = {};

        files.forEach(function (file, index) {
          console.log("Loading: " + file);

          fs.readFile(`./gas_usage/${contractDir}/${file}`, 'utf8', (err, data) => {
            if (err) {
              console.error(err)
              return
            }

            console.log(data)
            gasUsage[contractDir][file] = JSON.parse(data);
          });
        });
      });
    });
  });

  console.log(gasUsage);
  return gasUsage;
}

function buildComment(gasUsage) {
  const commentHeader = ```
    ![gas](https://liquipedia.net/commons/images/thumb/7/7e/Scr-gas-t.png/20px-Scr-gas-t.png) 
        ~ Gas Diff Report ~ 
    ![gas](https://liquipedia.net/commons/images/thumb/7/7e/Scr-gas-t.png/20px-Scr-gas-t.png)
  ```;

  var commentData = "";
  for (var contract in gasUsage) {
    commentData += `  * ${contract}:` + '\n';

    for (var f in gasUsage[contract]) {
      const mainUsage = gasUsage[contract][f]["main"];
      const prUsage = gasUsage[contract][f]["pr"];
      const pctChange = (prUsage - mainUsage) / mainUsage * 100;

      commentData += `    * ${f}:` + '\n';
      commentData += `      * Change: ${pctChange}%` + '\n';
      commentData += `      * main: ${github.event.pull_request.base.sha}: ${mainUsage} ` + '\n';
      commentData += `      * PR: ${github.sha}: ${prUsage}` + '\n\n';
    }
  }

  return commentHeader + '\n' + commentData;
}
