test_that("no_tab_linter skips allowed usages", {
  linter <- no_tab_linter()

  expect_lint("blah", NULL, linter)
  expect_lint("  blah", NULL, linter)
  expect_lint("  blah", NULL, linter)
  expect_lint("#\tblah", NULL, linter)
})

test_that("no_tab_linter blocks disallowed usages", {
  linter <- no_tab_linter()
  lint_msg <- rex::rex("Use spaces to indent, not tabs.")

  expect_lint(
    "\tblah",
    list(message = lint_msg, line_number = 1L, column_number = 1L, ranges = list(c(1L, 1L))),
    linter
  )

  expect_lint(
    "\n\t\t\tblah",
    list(message = lint_msg, line_number = 2L, column_number = 1L),
    linter
  )

  # ignore strings
  expect_lint(
    'lint_msg <- "dont flag tabs if\tthey are inside a string."',
    NULL,
    linter
  )
  # ignore multi-line strings
  expect_lint(
    'lint_msg <- "dont flag tabs if\n\tthey are inside multiline strings."',
    NULL,
    linter
  )
})
