# This file was generated using ft-templates
# https://github.com/seekrs/ft-templates

NAME := {{ PROJECT_NAME }}

DEBUG ?= 0
BONUS ?= 0

CC := clang
CFLAGS := -Wall -Wextra -Werror
LDFLAGS :=

SRC_DIR := src
SRC_MAIN := src/mandatory
SRC_SHARED := src/shared
SRC_BONUS := src/bonus
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj

{{# if GENSOURCES #}}
-include development.mk

ifeq ($(DEVELOPMENT), 1)
DEBUG := 1
_ := $(shell bash gensources.sh $(SRC_DIR))
endif
{{# endif #}}

ifeq ($(DEBUG), 1)
CFLAGS += -g3 -gdwarf-3 -ggdb
endif

include sources.mk

OBJS := $(patsubst %.c,%.o,$(patsubst %.s,%.o,$(patsubst %.cpp,%.o,$(SRCS))))
SRCS := $(addprefix $(SRC_DIR)/,$(SRCS))
OBJS := $(addprefix $(OBJ_DIR)/,$(OBJS))

all: $(NAME)

$(NAME): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@
