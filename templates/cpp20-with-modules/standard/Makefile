# This file was generated using ft-templates
# https://github.com/seekrs/ft-templates

NAME := {{PROJECT_NAME}}
MAKE := make --no-print-directory --debug=none
-include development.mk

SRC_DIR := src
INCLUDE_DIR := include
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj
MODULES_DIR := $(BUILD_DIR)/modules

ifeq ($(DEVELOPMENT), 1)
DEBUG := 1
USE_WARNINGS := 1
{{#GENSOURCES}}
_ := $(shell find $(SRC_DIR)/ -type f -name '*.cpp' | LC_ALL=C sort | sed 's/^src\//SRCS += /' > sources.mk)
_ := $(shell find $(SRC_DIR)/ -type f -name '*.cppm' | LC_ALL=C sort | sed 's/^src\//SRCS_MODULES += /' >> sources.mk)
{{/GENSOURCES}}
endif

DEBUG ?= 0

CXX ?= clang++
CXXFLAGS := -Wall -Wextra -I$(INCLUDE_DIR) -march=native -mtune=native -flto -std=c++23 -stdlib=libc++ -Wno-unused-command-line-argument -Wno-reserved-module-identifier
ifneq ($(USE_WARNINGS), 1)
CXXFLAGS += -Werror
endif
LDFLAGS := -stdlib=libc++ -flto

ifeq ($(DEBUG), 1)
CXXFLAGS += -g3 -gdwarf-3 -ggdb
endif

STD_MODULE_DIR := $(LIBCXX_SHARE_PATH)
STD_PCM := $(MODULES_DIR)/std.pcm

include sources.mk

OBJS := $(patsubst %.cpp,%.o,$(SRCS))
OBJS_MODULES := $(patsubst %.cppm,%.o,$(SRCS_MODULES))
PCMS_MODULES := $(patsubst %.cppm,%.pcm,$(SRCS_MODULES))
SRCS := $(addprefix $(SRC_DIR)/,$(SRCS))
SRCS_MODULES := $(addprefix $(SRC_DIR)/,$(SRCS_MODULES))
OBJS := $(addprefix $(OBJ_DIR)/,$(OBJS))
OBJS_MODULES := $(addprefix $(OBJ_DIR)/,$(OBJS_MODULES))
PCMS_MODULES := $(addprefix $(MODULES_DIR)/,$(PCMS_MODULES))

.PHONY: all
all:
	@$(MAKE) -j$(shell nproc) $(NAME)

$(NAME): $(OBJS) $(OBJS_MODULES)
	$(CXX) $(LDFLAGS) -o $@ $^

# std pcm
$(STD_PCM):
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 --precompile $(STD_MODULE_DIR)/std.cppm -fprebuilt-module-path=$(MODULES_DIR) -o $@

$(OBJ_DIR)/std.o: $(STD_PCM)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(MODULES_DIR)/%.pcm: $(SRC_DIR)/%.cppm $(STD_PCM)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -fprebuilt-module-path=$(MODULES_DIR) --precompile $< -o $@

# our pcm
$(OBJ_DIR)/%.o: $(MODULES_DIR)/%.pcm $(STD_PCM)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -fprebuilt-module-path=$(MODULES_DIR) -c $< -o $@

# .o
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp $(PCMS_MODULES)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -fprebuilt-module-path=$(MODULES_DIR) -c $< -o $@

.PHONY: fclean
oclean:
	@mv $(STD_PCM) /tmp/std.pcm
	rm -rf $(BUILD_DIR)
	@mkdir -p $(MODULES_DIR)
	@mv /tmp/std.pcm $(STD_PCM)

.PHONY: remake
remake: oclean all

.PHONY: clean
clean: oclean

.PHONY: fclean
fclean: oclean
	rm -rf $(NAME)
{{#CLANGD_SUPPORT}}

.PHONY: compile_commands.json
compile_commands.json: oclean
	bear -- $(MAKE) USE_WARNINGS=1 $(OBJS) 
{{/CLANGD_SUPPORT}}

.PHONY: re
re: fclean
	@$(MAKE) -j$(shell nproc) $(NAME)
