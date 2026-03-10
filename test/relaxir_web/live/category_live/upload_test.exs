defmodule RelaxirWeb.CategoryLive.UploadTest do
  use RelaxirWeb.ConnCase, async: true

  alias Relaxir.Repo

  describe "handle_params/3" do
    test "updates category image filename and redirects", %{conn: conn} do
      # Create a test user
      user = Relaxir.AccountsFixtures.user_fixture(%{email: "user@example.com", password: "password123"})
      _conn = log_in_user(conn, user)

      # Create a category directly
      {:ok, category} = Relaxir.Categories.create_category(%{name: "test-category"})

      # Create a recipe with the category to ensure it can be retrieved
      {:ok, recipe} = Relaxir.Recipes.create_recipe(%{
        title: "test recipe for category",
        directions: "test directions",
        categories: ["test-category"]
      })

      # Manually create the association in the database
      # This bypasses the issue with the recipe creation process not properly associating categories
      Repo.insert_all("recipe_categories", [
        %{recipe_id: recipe.id, category_id: category.id}
      ])

      # Reload the category to ensure it has the recipe association
      category = Relaxir.Categories.get_category!(category.id)

      # Create a socket with the necessary assigns
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          current_user: user
        }
      }

      # Call handle_params directly with valid parameters
      # This simulates being called as a callback from UploadLive
      {:noreply, updated_socket} = RelaxirWeb.CategoryLive.Upload.handle_params(
        %{"id" => Integer.to_string(category.id), "image_filename" => "test.jpg"},
        "/categories/#{category.id}/upload?image_filename=test.jpg",
        socket
      )

      # Verify it redirects to the category page
      encoded_name = URI.encode_www_form(category.name)
      assert updated_socket.redirected == {:live, :patch, %{kind: :push, to: "/categories/#{encoded_name}"}}

      # Verify the category was updated with the image filename
      updated_category = Relaxir.Categories.get_category!(category.id)
      assert updated_category.image_filename == "test.jpg"
    end
  end
end
