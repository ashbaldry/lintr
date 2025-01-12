#' Require usage of correctly-typed literals over literal coercions
#'
#' `as.integer(1)` (or `rlang::int(1)`) is the same as `1L` but the latter is
#' more concise and gets typed correctly at compilation.
#'
#' The same applies to missing sentinels like `NA` -- typically, it is not
#'   necessary to specify the storage type of `NA`, but when it is, prefer
#'   using the typed version (e.g. `NA_real_`) instead of a coercion
#'   (like `as.numeric(NA)`).
#'
#' @examples
#' # will produce lints
#' lint(
#'   text = "int(1)",
#'   linters = literal_coercion_linter()
#' )
#'
#' lint(
#'   text = "as.character(NA)",
#'   linters = literal_coercion_linter()
#' )
#'
#' lint(
#'   text = "rlang::lgl(1L)",
#'   linters = literal_coercion_linter()
#' )
#'
#' # okay
#' lint(
#'   text = "1L",
#'   linters = literal_coercion_linter()
#' )
#'
#' lint(
#'   text = "NA_character_",
#'   linters = literal_coercion_linter()
#' )
#'
#' lint(
#'   text = "TRUE",
#'   linters = literal_coercion_linter()
#' )
#'
#' @evalRd rd_tags("literal_coercion_linter")
#' @seealso [linters] for a complete list of linters available in lintr.
#' @export
literal_coercion_linter <- function() {
  coercers <- xp_text_in_table(
    c(
      # base coercers
      paste0("as.", c("logical", "integer", "numeric", "double", "character")),
      # rlang coercers
      c("lgl", "int", "dbl", "chr")
    )
  )

  # notes for clarification:
  #  - as.integer(1e6) is arguably easier to read than 1000000L
  #  - in x$"abc", the "abc" STR_CONST is at the top level, so exclude OP-DOLLAR
  #  - need condition against STR_CONST w/ EQ_SUB to skip quoted keyword arguments (see tests)
  #  - for {rlang} coercers, both `int(1)` and `int(1, )` need to be linted
  not_extraction_or_scientific <- "
    not(OP-DOLLAR)
    and (
      NUM_CONST[not(contains(translate(text(), 'E', 'e'), 'e'))]
      or STR_CONST[not(following-sibling::*[1][self::EQ_SUB])]
    )
  "
  xpath <- glue::glue("
  //SYMBOL_FUNCTION_CALL[ {coercers} ]
    /parent::expr
    /parent::expr[
      count(expr) = 2
      and expr[2][ {not_extraction_or_scientific} ]
    ]
  ")

  Linter(function(source_expression) {
    if (!is_lint_level(source_expression, "expression")) {
      return(list())
    }

    xml <- source_expression$xml_parsed_content

    bad_expr <- xml2::xml_find_all(xml, xpath)

    xml_nodes_to_lints(
      bad_expr,
      source_expression = source_expression,
      lint_message = paste(
        "Use literals directly where possible, instead of coercion.",
        "c.f. 1L instead of as.integer(1) or rlang::int(1), or NA_real_ instead of as.numeric(NA)."
      ),
      type = "warning"
    )
  })
}
