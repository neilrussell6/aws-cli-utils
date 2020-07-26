all: main

main: src/common/*.consts.* src/common/*.utils.* src/modules/*/*.utils.* src/modules/*/*.index.* src/index.sh
	@echo "#!/usr/bin/env bash" > "dist/${@}" && cat $^ >> "dist/${@}" || (rm -f "dist/${@}"; exit 1)
	@chmod u+x ./dist/main

install: main
	@cp ./dist/main /usr/local/bin/aws-cli-utils
