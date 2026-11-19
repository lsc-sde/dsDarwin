test_that("buildDSCall sends symbols as symbols, values as values", {
  call <- buildDSCall("fooDS", cdm = AsSymbol("cdm"), name = "x", n = 3)
  expect_identical(call, quote(fooDS(cdm = cdm, name = "x", n = 3)))
})

test_that("AsSymbol accepts object$element", {
  expect_identical(buildDSCall("f", cohort = AsSymbol("cdm$gibleed")), quote(f(cohort = cdm$gibleed)))
})

test_that("a string with quotes and code stays one plain value", {
  call <- buildDSCall("f", x = "a'); ls(); ('")
  expect_identical(call[["x"]], "a'); ls(); ('")
  expect_length(call, 2)
})

test_that("findConnections refuses things that are not DSConnections", {
  expect_error(findConnections(list(1)), "DSConnection")
})
