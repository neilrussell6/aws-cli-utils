all: main

main: src/common/*.consts.* src/common/*.utils.* src/modules/*/*.utils.* src/modules/*/*.index.* src/index.sh
	@cat $^ > "dist/${@}" || (rm -f "dist/${@}"; exit 1)
