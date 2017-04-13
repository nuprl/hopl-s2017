ANNOTATED="annotated.tex"
OUTLINE="soft-typing"

all: annotated outline

annotated:
	xelatex ${ANNOTATED}

outline:
	xelatex ${OUTLINE}
	bibtex ${OUTLINE}
	xelatex ${OUTLINE}
	xelatex ${OUTLINE}
