test_that("nfilterTab reads nfilter.tab first", {
  withr::local_options(nfilter.tab = 5, default.nfilter.tab = 3)
  expect_equal(nfilterTab(), 5)
})

test_that("nfilterTab falls back to default.nfilter.tab", {
  withr::local_options(nfilter.tab = NULL, default.nfilter.tab = 3)
  expect_equal(nfilterTab(), 3)
})

test_that("nfilterTab fails closed when no threshold is set", {
  withr::local_options(nfilter.tab = NULL, default.nfilter.tab = NULL)
  expect_error(nfilterTab(), "threshold")
})

test_that("applyDisclosureControl hides counts between 0 and the threshold", {
  withr::local_options(nfilter.tab = 5)
  counts <- data.frame(number_records = c(0L, 2L, 10L), number_subjects = c(0L, 2L, 7L))
  out <- applyDisclosureControl(counts)
  expect_identical(out$number_records, c(0L, NA, 10L))
  expect_identical(out$number_subjects, c(0L, NA, 7L))
})

test_that("nfilterTab fails closed on a malformed threshold", {
  for (bad in list(NA, "", "abc", c(3, 10), 0)) {
    withr::local_options(nfilter.tab = bad)
    expect_error(nfilterTab(), "threshold")
  }
})

test_that("nfilterTab accepts a threshold set as a string, as Opal options are", {
  withr::local_options(nfilter.tab = "5")
  expect_equal(nfilterTab(), 5)
})
