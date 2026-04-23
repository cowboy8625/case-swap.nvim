local case_swap = require("case-swap")

describe("case conversions", function()
  before_each(function()
    vim.cmd("enew!")
  end)

  it("convert title to snake", function()
    local result = case_swap.convert("HelloWorld", case_swap.CaseKind.snake)
    assert.are_equal(result, "hello_world")
  end)

  it("convert title to camel", function()
    local result = case_swap.convert("HelloWorld", case_swap.CaseKind.camel)
    assert.are_equal(result, "helloWorld")
  end)

  it("convert title to kebab", function()
    local result = case_swap.convert("HelloWorld", case_swap.CaseKind.kebab)
    assert.are_equal(result, "hello-world")
  end)

  it("convert snake to title", function()
    local result = case_swap.convert("hello_world", case_swap.CaseKind.title)
    assert.are_equal(result, "HelloWorld")
  end)

  it("convert snake to camel", function()
    local result = case_swap.convert("hello_world", case_swap.CaseKind.camel)
    assert.are_equal(result, "helloWorld")
  end)

  it("convert snake to kebab", function()
    local result = case_swap.convert("hello_world", case_swap.CaseKind.kebab)
    assert.are_equal(result, "hello-world")
  end)

  it("convert camel to title", function()
    local result = case_swap.convert("helloWorld", case_swap.CaseKind.title)
    assert.are_equal(result, "HelloWorld")
  end)

  it("convert camel to snake", function()
    local result = case_swap.convert("helloWorld", case_swap.CaseKind.snake)
    assert.are_equal(result, "hello_world")
  end)

  it("convert camel to kebab", function()
    local result = case_swap.convert("helloWorld", case_swap.CaseKind.kebab)
    assert.are_equal(result, "hello-world")
  end)

  it("convert kebab to title", function()
    local result = case_swap.convert("hello-world", case_swap.CaseKind.title)
    assert.are_equal(result, "HelloWorld")
  end)

  it("convert kebab to snake", function()
    local result = case_swap.convert("hello-world", case_swap.CaseKind.snake)
    assert.are_equal(result, "hello_world")
  end)

  it("convert kebab to camel", function()
    local result = case_swap.convert("hello-world", case_swap.CaseKind.camel)
    assert.are_equal(result, "helloWorld")
  end)

  -- edge cases
  it("preserves numbers and acronyms in snake conversion", function()
    local result = case_swap.convert("SomeHTMLValue2", case_swap.CaseKind.snake)
    assert.are_equal(result, "some_html_value2")
  end)

  it("empty string returns empty", function()
    local result = case_swap.convert("", case_swap.CaseKind.camel)
    assert.are_equal(result, "")
  end)

  it("detect case kind", function()
    assert.are_equal(case_swap.detect_case_kind("HelloWorld"), case_swap.CaseKind.title)
    assert.are_equal(case_swap.detect_case_kind("hello_world"), case_swap.CaseKind.snake)
    assert.are_equal(case_swap.detect_case_kind("helloWorld"), case_swap.CaseKind.camel)
    assert.are_equal(case_swap.detect_case_kind("hello-world"), case_swap.CaseKind.kebab)
  end)
end)
