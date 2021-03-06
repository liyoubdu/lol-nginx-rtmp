#!/bin/sh

CUR_DIR=$(pwd)
ROOT_DIR=$(dirname $(readlink -f $0))
cd $ROOT_DIR

BUILD_DIR=$ROOT_DIR/buildGb28181Nginx
DEBUG=release
VSCODE_GDB_DIR=$ROOT_DIR
################################################## compile nginx
function compileNginx {
	rm -rf $ROOT_DIR/nginx/sbin/*
	make
	make install
	echo "####################################################"
	echo "done to build nginx"
}

################################################## get argument
for option   #option是内置变量，代表了当前脚本程序的参数集合(不含脚本程序名)
do
	case "$option" in
		*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
		*) value="" ;;
	esac
	case "$option" in
		debug=*) debugOpt="$value" ;;
		debug=*) debugOpt="$value" ;;
		compileonly=*) compileOpt="$value" ;;
		compileOnly=*) compileOpt="$value" ;;
	esac
done

echo "debugOpt=$debugOpt compileOpt=$compileOpt"
echo "**************************************************"
#sleep 3

################################################## we compile nginx only and simply
if [ ! -z $debugOpt ]; then
	DEBUG=debug
fi

if [ ! -z $compileOpt ]; then
	cd $BUILD_DIR/nginx-1.14.0
	compileNginx
	exit 0
fi

################################################## generate nginx-build environment, and configure nginx
cd $ROOT_DIR
chmod a+x compile.sh
rm -rf nginx
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

#检测：编译目录是否创建成功，是否能新建文件。
echo "temp" > $BUILD_DIR/.heb1
if [  $? -ne 0 ];then
	echo "fail to test: can not create new file in $BUILD_DIR"
	exit 1
fi
rm -rf $BUILD_DIR/.heb*

tar zxf ./doc/nginx-1.14.0.tar.gz -C $BUILD_DIR
cd $BUILD_DIR/nginx-1.14.0
./configure --with-stream --with-debug --prefix=$ROOT_DIR/nginx --add-module=$ROOT_DIR

#移除ipv6的支持。
chmod a+w ./objs/ngx_auto_config.h
sed 's/#define NGX_HAVE_INET6  1/#define NGX_HAVE_INET6  0/g' < ./objs/ngx_auto_config.h > .heb2
mv .heb2 ./objs/ngx_auto_config.h

#编译nginx，并创建配置文件
compileNginx
rm -rf $ROOT_DIR/nginx/conf/nginx.conf
cp $ROOT_DIR/../doc/nginx.conf $ROOT_DIR/nginx/conf/

#设置vscode的gdb配置。
VSCODE_GDB_DIR=$VSCODE_GDB_DIR/.vscode
rm -rf $VSCODE_GDB_DIR
mkdir -p $VSCODE_GDB_DIR
GDB_CFG_PATH=$VSCODE_GDB_DIR/launch.json
sed 's|aOut|'"$ROOT_DIR"'/nginx/sbin/nginx|g' < $ROOT_DIR/../doc/vscode.launch.json > $GDB_CFG_PATH
cat $GDB_CFG_PATH
