defmodule SerumRecipes.Plugin.Loader do
  require EEx
  @behaviour Serum.Plugin
  @recipes_temporary_path "_recipes"

  def name, do: "SerumRecipes.Plugin.Loader"
  def version, do: "0.0.1"
  def elixir, do: "~> 1.12"
  def serum, do: ">= 0.5.0"
  def description, do: "Loads recipes in schema.org format for Serum site generator"

  def implements do
    [
      build_started: 3,
      finalizing: 3,
      reading_pages: 2,
    ]
  end

  def build_started(_src, _dest, _args) do
    unless File.exists? @recipes_temporary_path do
      File.mkdir! @recipes_temporary_path
    end

    Path.wildcard("pages/*.recipe.yaml")
      |> Enum.each(&generate_recipe_md_file/1)

    :ok
  end

  def finalizing(_src, _dest, _args) do
    recipes_output_path = "site/#{@recipes_temporary_path}"

    File.rm_rf! @recipes_temporary_path
    File.cp_r! recipes_output_path, "site"
    File.rm_rf! recipes_output_path
    :ok
  end

  def reading_pages(files, _args) do
    recipe_files = File.ls!(@recipes_temporary_path)
      |> Enum.map(fn file -> "#{@recipes_temporary_path}/#{file}" end)

    {:ok, files ++ recipe_files}
  end

  defp debug(msg), do: IO.puts("\x1b[90m#{name()} #{msg}\x1b[0m")

  defp format_duration(iso_duration) do
    debug("**** I was called with #{iso_duration}")

    Timex.Duration.parse!(iso_duration)
      |> Timex.Format.Duration.Formatters.Humanized.format
  end

  defp generate_recipe_md_file(yaml_path) do
    [ recipe_slug ] = Regex.run ~r/pages\/([A-Za-z0-9\-]+)/, yaml_path, capture: :all_but_first
    recipe = YamlElixir.read_from_file!(yaml_path)

    md_content = recipe_md(
      recipe["cookTime"],
      recipe["description"],
      recipe["image"],
      recipe["recipeIngredient"],
      recipe["recipeInstructions"],
      recipe["prepTime"],
      recipe["name"],
      recipe["recipeYield"]
    )

    File.write! "#{@recipes_temporary_path}/#{recipe_slug}.md", md_content
    :ok
  end

  EEx.function_from_file(
    :defp,
    :recipe_md,
    "#{File.cwd!}/lib/recipe_template.md.eex",
    ~w(
      cook_time
      description
      image
      ingredients
      instructions
      prep_time
      title
      yield
    )a
  )
end
