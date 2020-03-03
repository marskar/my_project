PROJ_NAME = my_project
PROJ_DESC = "A short description of the project."
VENV_ROOT = ~/miniconda
VENV_NAME = $(PROJ_NAME)
VENV_PATH = $(VENV_ROOT)/envs/$(VENV_NAME)
REPO_NAME = $(PROJ_NAME)
USER_NAME = marskar

all: env git test lint

env: $(VENV_PATH)/bin/activate

$(VENV_PATH)/bin/activate: environment.yml
	conda env update -n $(VENV_NAME) --file environment.yml
	touch $(VENV_PATH)/bin/activate

environment.yml:
	conda create -yn $(VENV_NAME) python=3.8 black pytest pytest-mypy r-styler r-testthat
	conda env export --from-history -n $(VENV_NAME) > environment.yml

git: .git/

.git/:
	curl https://api.github.com/user/repos --data '{"name":"$(PROJ_NAME)","description":$(PROJ_DESC)}' --user $(USER_NAME)
	test -f README.md || echo "$(PROJ_NAME)" >> README.md
	git init
	git add --all
	git commit --message "First commit to the project named $(PROJ_NAME)"
	git remote add origin https://github.com/$(USER_NAME)/$(REPO_NAME)
	git push --set-upstream origin master

push:
	git commit --all --message "Changed files: $$(git status --porcelain | grep -v '?' | cut -c4- | tr '\n' ' ')"
	git push

amend:
	git commit --all --amend --reset-author --reuse-message=HEAD
	git push --force

# Python-specific section
pytest: env pytest.ini
	$(VENV_PATH)/bin/pytest

pytest.ini:
	echo "[pytest]\naddopts = --mypy --mypy-ignore-missing-imports --doctest-modules" > pytest.ini

pylint: env
	$(VENV_PATH)/bin/black

# R-specific section
rtest: env
	$(VENV_PATH)/bin/Rscript -e "testthat::test_dir(tests/testthat)"

rlint: env
	$(VENV_PATH)/bin/Rscript -e "styler::style_dir()"

.PHONY: env git push amend test lint
