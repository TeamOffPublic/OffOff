# secret key의 경우 타인에게 노출되면 안 되기 때문에 별도의 파일을 만들어서 저장한다. 
# 이 때, 해당 파일은 git.ignore을 통해 git repo에 올라가지 않도록 설정해야 한다.
# 알고리즘도 같은 파일에 넣음

SECRET_KEY = 'OFNURCOMULEPAKIM'
ALGORITHM = 'HS256'