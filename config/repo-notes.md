git repo的管理

2个维度：
1. 该repo的用途，比如说是jenkins的，ansible的，springboot，mall等
2. 所在的git server，如 git, gitee, github等

分成多个文件，如：
    gitee-jenkins.repo
    gitee-spring.repo 
    github-mall.repo
    github-spring.repo 

即文件名称中包含所属的git server及代码所属的类别
内容计委各repo的名称

clonegit.sh gitee-jenkins 。。。。。。

创建目录时，根目录为代码所属的类别，如jenkins，spring等，如下：
/jenkins 
    /user1/repo1
    /user2/repo2
不包含git server的名称

同时生成一个文件，包含所有的repo的https链接及clone的命令，如：
git clone https://git.com/user1/repo1 $TARGET_DIR
    有无此必要？
    还是有的，仅有url，没有目标路径还是不行！



