defmodule RecipeTransformer do
  @behaviour Serum.Plugin

  def name, do: "RecipeTransformer"
  def version, do: "0.0.1"
  def elixir, do: "~> 1.12"
  def serum, do: ">= 0.5.0"
  def description, do: "Loads Open Recipe Format for Serum site generator"

  def implements do
    [
      reading_pages: 2,
      processing_page: 1,
    ]
  end

  def reading_pages(files, _args) do
    debug("**** READING PAGES *****: #{files}")

    {:ok, files}
  end

  def processing_page(file) do
    debug("**** HEY I GOT THIS FILE *****: #{file.src}")

    recipe_path = String.split(file.src, ".")
      |> List.replace_at(-1, "recipe.yaml")
      |> Enum.join(".")

    debug("*** Is this...a recipe? #{recipe_path}")

    if File.exists?(recipe_path) do
      recipe = File.cwd!
        |> Path.join(recipe_path)
        |> YamlElixir.read_from_file

      debug("***** I got this #{recipe.recipe_name}")

      # recipe_data = File.read! recipe_file

    end

    {:ok, file}
  end

  defp debug(msg), do: IO.puts("\x1b[90m#{name()} #{msg}\x1b[0m")
end
