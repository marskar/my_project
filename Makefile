PROJ_NAME = my_project
PROJ_DESC = "A short description of the project."
VENV_ROOT = ~/miniconda
VENV_NAME = $(PROJ_NAME)
VENV_PATH = $(VENV_ROOT)/envs/$(VENV_NAME)
REPO_NAME = $(PROJ_NAME)
USER_NAME = marskar

all: env git

# Conda environment setup
env: $(VENV_PATH)/bin/activate

$(VENV_PATH)/bin/activate: environment.yml
	conda env update -n $(VENV_NAME) --file environment.yml
	touch $(VENV_PATH)/bin/activate

environment.yml:
	conda create -yn $(VENV_NAME)
	conda env export --from-history -n $(VENV_NAME) > environment.yml

# Git setup
git: .git/

.git/:
	curl https://api.github.com/user/repos --data '{"name":"$(PROJ_NAME)","description":$(PROJ_DESC)}' --user $(USER_NAME)
	test -f README.md || echo "$(PROJ_NAME)" >> README.md
	git init
	git add --all
	git commit --message "First commit to the project named $(PROJ_NAME)"
	git remote add origin https://github.com/$(USER_NAME)/$(REPO_NAME)
	git push --set-upstream origin master

# Git workflow
.gitignore:
	echo ".mypy_cache\n__pycache__" > .gitignore

add: git
	git add --update

commit: add
	git commit --message "Changed files: $$(git status --porcelain | grep -v '?' | cut -c4- | tr '\n' ' ')"

push: commit
	git push

amend:
	git add --update
	git commit --amend --reset-author --reuse-message=HEAD
	git push --force

# Python-specific section (delete if not needed)
pytest: $(VENV_PATH)/bin/black pytest.ini
	$(VENV_PATH)/bin/pytest

$(VENV_PATH)/bin/black:
	conda install -n $(VENV_NAME) python=3.8 black
	conda env export --from-history -n $(VENV_NAME) > environment.yml
	touch $(VENV_PATH)/bin/activate

$(VENV_PATH)/bin/pytest:
	conda install -n $(VENV_NAME) python=3.8 pytest pytest-mypy
	conda env export --from-history -n $(VENV_NAME) > environment.yml
	touch $(VENV_PATH)/bin/activate

pytest.ini:
	echo "[pytest]\naddopts = --mypy --mypy-ignore-missing-imports --doctest-modules" > pytest.ini

pylint: $(VENV_PATH)/bin/black
	$(VENV_PATH)/bin/black

# R-specific section (delete if not needed)
$(VENV_PATH)/lib/R/library/testthat:
	conda install -n $(VENV_NAME) r-testthat
	conda env export --from-history -n $(VENV_NAME) > environment.yml
	touch $(VENV_PATH)/bin/activate

$(VENV_PATH)/lib/R/library/styler:
	conda install -n $(VENV_NAME) r-styler
	conda env export --from-history -n $(VENV_NAME) > environment.yml
	touch $(VENV_PATH)/bin/activate

rtest: $(VENV_PATH)/lib/R/library/testthat
	mkdir -p tests/testthat
	$(VENV_PATH)/bin/Rscript -e "testthat::test_dir('tests/testthat')"

rlint: $(VENV_PATH)/lib/R/library/styler
	$(VENV_PATH)/bin/Rscript -e "styler::style_dir()"

.PHONY: env git add commit push amend pytest pylint rtest rlint
