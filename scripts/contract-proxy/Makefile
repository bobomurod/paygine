makeabi:
	@mkdir abi
	@cp -R -f \
		../build/contracts/* \
		$(shell pwd)/abi

dev: abi
	@$(shell pwd)/node_modules/.bin/cross-env \
		WEB3=https://rinkeby.infura.io/B0QFpfZKeuLFhhW3zZeu\
		PRIVATE_KEY=37c64b70f61f6070b9854a1b36c852f7f455bcd1016077b2db8fa79c377e2979\
		FROM=0x2663472512d48ae0f22e8529d59C12585cDAA524\
		GAS_PRICE=1000000000\
		DEBUG=error,warning,info,log,verb \
		$(shell pwd)/node_modules/.bin/nodemon $(shell pwd)/app.js $@ --exec $(shell pwd)/node_modules/.bin/babel-node

run:
	@$(shell pwd)/node_modules/.bin/cross-env \
		WEB3=https://rinkeby.elastoo.com:443\
		PRIVATE_KEY=42b775ab6289ba7eade47d793b2c24c30797652bf2007d19c9b8935da02a8f01\
		FROM=0x913752F3Db97e282cED23f8B16826f596359b8Dc\
		GAS_PRICE=1000000000\
		DEBUG=error,warning,info,log \
		$(shell pwd)/node_modules/.bin/babel-node $(shell pwd)/app.js $@

install:
	@npm install
