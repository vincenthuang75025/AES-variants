julia := "julia --threads 2 --project=."

install:
    {{julia}} -e "import Pkg; Pkg.instantiate()"

repl:
    {{julia}}

notebook:
    {{julia}} -e "import Pluto; Pluto.run()"

check:
    if [[ $(git diff --name-only) ]]; then \
        >&2 echo "Please run check on a clean Git working tree."; \
        exit 1; \
    fi

test:
    {{julia}} -e "import Pkg; Pkg.test()";

ecb-profile:
    {{julia}} test/AES-old/ecb-profile.jl;

add-package:
    {{julia}} -e "import Pkg; Pkg.add(\"NAME\")";