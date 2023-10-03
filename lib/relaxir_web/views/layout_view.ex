defmodule RelaxirWeb.LayoutView do
  use RelaxirWeb, :view

  def meta_tags(attrs) do
    Enum.map(attrs, &meta_tag/1)
  end

  def meta_tag(attrs) do
    tag(:meta, Enum.into(attrs, []))
  end
end
