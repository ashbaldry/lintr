#' Force consecutive calls to stopifnot into just one when possible
#'
#' [stopifnot()] accepts any number of tests, so sequences like
#'   `stopifnot(x); stopifnot(y)` are redundant.
#'
#' @examples
#' # will produce lints
#' lint(
#'   text = "stopifnot(x); stopifnot(y)",
#'   linters = consecutive_stopifnot_linter()
#' )
#'
#' # okay
#' lint(
#'   text = "stopifnot(x, y)",
#'   linters = consecutive_stopifnot_linter()
#' )
#'
#' @evalRd rd_tags("consecutive_stopifnot_linter")
#' @seealso [linters] for a complete list of linters available in lintr.
#' @export
consecutive_stopifnot_linter <- function() {
  # match on the expr, not the SYMBOL_FUNCTION_CALL, to ensure
  #   namespace-qualified calls only match if the namespaces do.
  xpath <- "
  //SYMBOL_FUNCTION_CALL[text() = 'stopifnot']
    /parent::expr
    /parent::expr[expr[1] = following-sibling::expr[1]/expr]
  "

  Linter(function(source_expression) {
    # need the full file to also catch usages at the top level
    if (!is_lint_level(source_expression, "file")) {
      return(list())
    }

    xml <- source_expression$full_xml_parsed_content

    bad_expr <- xml2::xml_find_all(xml, xpath)

    xml_nodes_to_lints(
      bad_expr,
      source_expression = source_expression,
      lint_message = "Unify consecutive calls to stopifnot().",
      type = "warning"
    )
  })
}
