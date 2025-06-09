# This file was generated using ft-templates
# https://github.com/seekrs/ft-templates

NAME := {{PROJECT_NAME}}
-include development.mk

ifeq ($(DEVELOPMENT), 1)
DEBUG := 1
USE_WARNINGS := 1
{{#GENSOURCES}}
_ := $(shell bash gensources.sh sources.mk $(SRC_DIR))
{{/GENSOURCES}}
endif

DEBUG ?= 0
BONUS ?= 0

CC := clang
CXX := clang++
CFLAGS := -Wall -Wextra
ifneq ($(USE_WARNINGS), 1)
CFLAGS += -Werror
endif
CXXFLAGS := $(CFLAGS)
LDFLAGS :=

NASM := nasm
NASMFLAGS := -f elf64

SRC_DIR := src
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj

ifeq ($(DEBUG), 1)
CFLAGS += -g3 -gdwarf-3 -ggdb
NASMFLAGS += -g
endif

include sources.mk

OBJS := $(patsubst %.c,%.o,$(patsubst %.s,%.o,$(patsubst %.cpp,%.o,$(SRCS))))
SRCS := $(addprefix $(SRC_DIR)/,$(SRCS))
OBJS := $(addprefix $(OBJ_DIR)/,$(OBJS))

LIB_DIR := third-party
{{#LIBRARIES}}
LIBRARIES += {{.}}
{{.}}_URL := {{(. '_URL')}}
{{.}}_DIR := $(LIB_DIR)/{{.}}
{{.}}_DEP := $({{.}}_DIR)/{{(. '_LIB')}}
CFLAGS += -I$({{.}}_DIR)/include -I$({{.}}_DIR)/includes
LDFLAGS += $({{.}}_DEP)
DEPFILES += $({{.}}_DEP)
{{/LIBRARIES}}
{{#USE_MACROLIBX}}
LDFLAGS += -lSDL2
{{/USE_MACROLIBX}}

all:
	$(MAKE) -j$(shell nproc) $(NAME)

$(NAME): $(OBJS) $(DEPFILES)
	$(CC) $(LDFLAGS) -o $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(dir $@)
	$(NASM) $(NASMFLAGS) $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@
{{#LIBRARIES}}

$({{.}}_DEP):
	make -C $({{.}}_DIR) -j$(shell nproc)
{{/LIBRARIES}}

oclean:
	rm -rf $(BUILD_DIR)

clean: oclean
{{#LIBRARIES}}
	make -C $({{.}}_DIR) clean
{{/LIBRARIES}}

fclean: oclean
{{#LIBRARIES}}
	make -C $({{.}}_DIR) fclean
{{/LIBRARIES}}
	rm -rf $(NAME)
{{#CLANGD_SUPPORT}}

compile_commands.json: oclean
	bear -- $(MAKE) USE_WARNINGS=1 $(OBJS) 
{{/CLANGD_SUPPORT}}

re: fclean
	$(MAKE) -j$(shell nproc) $(NAME)

.PHONY: all clean oclean fclean re
