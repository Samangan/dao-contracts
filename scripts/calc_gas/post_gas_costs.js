const fs = require('fs');

module.exports = async ({ github, context, core }) => {
  const gasUsage = getGasUsage();
  const commentBody = buildComment(gasUsage, github.base_ref, github.sha);

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

  const contractDirs = fs.readdirSync("./gas_usage/");

  contractDirs.forEach(function (contractDir) {
    console.log(`Processing ${contractDir}`);
    gasUsage[contractDir] = {};

    const files = fs.readdirSync(`./gas_usage/${contractDir}`);
    files.forEach(function (file) {
      console.log(`Loading: ${file}`);

      const data = fs.readFileSync(`./gas_usage/${contractDir}/${file}`, 'utf8');
      gasUsage[contractDir][file] = JSON.parse(data);
    });
  });

  return gasUsage;
}

function buildComment(gasUsage, baseSha, sha) {
  const commentHeader = `
    ![gas](https://liquipedia.net/commons/images/thumb/7/7e/Scr-gas-t.png/20px-Scr-gas-t.png) 
        ~ Gas Diff Report ~ 
    ![gas](https://liquipedia.net/commons/images/thumb/7/7e/Scr-gas-t.png/20px-Scr-gas-t.png)
  `;

  var commentData = "";
  for (var contract in gasUsage) {
    commentData += `  * ${contract}:` + '\n';

    for (var f in gasUsage[contract]) {
      const mainUsage = gasUsage[contract][f]["main"];
      const prUsage = gasUsage[contract][f]["pr"];
      const pctChange = (prUsage - mainUsage) / mainUsage * 100;

      commentData += `    * ${f}:` + '\n';
      commentData += `      * Change: ${pctChange}%` + '\n';
      commentData += `      * main: ${baseSha}: ${mainUsage} ` + '\n';
      commentData += `      * PR: ${sha}: ${prUsage}` + '\n\n';
    }
  }

  return commentHeader + '\n' + commentData;
}
