defmodule SerumRecipes.Plugin.Loader do
  require EEx
  import Serum.IOProxy, only: [ put_msg: 2 ]

  @behaviour Serum.Plugin
  @markdown_temporary_path "/tmp/recipes"
  @html_output_path "/recipes"

  def name, do: "SerumRecipes.Plugin.Loader"
  def version, do: "0.0.1"
  def elixir, do: "~> 1.12"
  def serum, do: ">= 0.5.0"
  def description, do: "Loads recipes in schema.org format for Serum site generator"

  def implements do
    [
      build_started: 3,
      finalizing: 3,
      processed_page: 2,
      reading_pages: 2,
      rendered_page: 2
    ]
  end

  def build_started(_src, _dest, args) do
    unless File.exists? @markdown_temporary_path do
      debug "Creating temporary directory for recipe markdown files: #{@markdown_temporary_path}"
      File.mkdir! @markdown_temporary_path
    end

    source_directory = args[:source_directory] || "pages"

    Path.wildcard("#{source_directory}/*/*.recipe.yaml")
      |> Enum.each(&generate_recipe_md_file(&1, source_directory))

    :ok
  end

  def finalizing(_src, _dest, _args) do
    if File.exists? @markdown_temporary_path do
      debug "Removing temporary directory for recipe markdown files: #{@markdown_temporary_path}"
      # File.rm_rf! @markdown_temporary_path
    end

    :ok
  end

  def processed_page(page, _args) do
    updated_page = %{page | output: replace_paths(page.output)}

    { :ok, updated_page }
  end

  def reading_pages(files, _args) do
    recipe_files = File.ls!(@markdown_temporary_path)
      |> Enum.map(fn file -> "#{@markdown_temporary_path}/#{file}" end)

    {:ok, files ++ recipe_files}
  end

  def rendered_page(file, _args) do
    updated_file = %{file | out_data: replace_paths(file.out_data)} # TODO this is gross

    { :ok, updated_file }
  end

  defp debug(msg), do: put_msg(:debug, msg)

  defp format_duration(iso_duration) do
    Timex.Duration.parse!(iso_duration)
      |> Timex.Format.Duration.Formatters.Humanized.format
  end

  defp generate_recipe_md_file(yaml_path, src_dir) do
    [ category_slug, recipe_slug ] = Regex.run(
      ~r/#{src_dir}\/([A-Za-z0-9\-]+)\/([A-Za-z0-9\-]+)/,
      yaml_path,
      capture: :all_but_first
    )

    category = Recase.to_sentence category_slug
    recipe = YamlElixir.read_from_file! yaml_path

    md_content = recipe_md(
      recipe["cookTime"],
      recipe["description"],
      category,
      recipe["image"],
      recipe["recipeIngredient"],
      recipe["recipeInstructions"],
      recipe["prepTime"],
      recipe["name"],
      recipe["recipeYield"]
    )

    md_path = "#{@markdown_temporary_path}/#{recipe_slug}.md"
    debug("Writing #{recipe["name"]} to #{md_path}")
    File.write! md_path, md_content
    :ok
  end

  defp replace_paths(str) do
    String.replace(str, @markdown_temporary_path, @html_output_path)
  end

  EEx.function_from_file(
    :defp,
    :recipe_md,
    "#{File.cwd!}/lib/recipe_template.md.eex",
    ~w(
      cook_time
      description
      group
      image
      ingredients
      instructions
      prep_time
      title
      yield
    )a
  )
end
