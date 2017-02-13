ANNOTATED="annotated.tex"
OUTLINE="datalog-for-static-analysis"

all: annotated outline

annotated:
	xelatex ${ANNOTATED}

outline:
	xelatex ${OUTLINE}
	bibtex ${OUTLINE}
	xelatex ${OUTLINE}
	xelatex ${OUTLINE}
