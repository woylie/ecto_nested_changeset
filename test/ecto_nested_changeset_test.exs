defmodule EctoNestedChangesetTest do
  use ExUnit.Case

  import Ecto.Changeset
  import EctoNestedChangeset

  alias __MODULE__.Category
  alias __MODULE__.Comment
  alias __MODULE__.Post
  alias Ecto.Changeset

  defmodule Category do
    use Ecto.Schema

    schema "categories" do
      has_many :posts, EctoNestedChangesetTest.Post, on_replace: :delete
      embeds_many :blocks, EctoNestedChangesetTest.Block, on_replace: :delete
    end
  end

  defmodule Comment do
    use Ecto.Schema

    schema "comments" do
      belongs_to :post, EctoNestedChangesetTest.Post
    end
  end

  defmodule Post do
    use Ecto.Schema

    schema "posts" do
      field :delete, :boolean, virtual: true, default: false
      field :title, :string
      field :tags, {:array, :string}, default: []
      belongs_to :category, EctoNestedChangesetTest.Category
      has_many :comments, EctoNestedChangesetTest.Comment
    end
  end

  defmodule Block do
    use Ecto.Schema

    embedded_schema do
      field :delete, :boolean, virtual: true, default: false
      field :text, :string
    end
  end

  describe "append_at/3" do
    test "appends item at a root level field without data" do
      changeset =
        %Category{id: 1, posts: []}
        |> change()
        |> append_at(:posts, %Post{title: "first"})
        |> append_at(:posts, %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{action: :insert, data: %Post{title: "first"}},
                 %Ecto.Changeset{action: :insert, data: %Post{title: "second"}}
               ]
             } = changeset.changes
    end

    test "doesn't raise error if field of unpersisted resource is not loaded" do
      %Category{id: 1}
      |> change()
      |> append_at(:posts, %Post{title: "first"})
    end

    test "raises error if field of persisted resource is not preloaded" do
      assert_raise EctoNestedChangeset.NotLoadedError,
                   "field `:posts` is not loaded",
                   fn ->
                     %Category{id: 1}
                     |> Map.update!(:__meta__, &Map.put(&1, :state, :loaded))
                     |> change()
                     |> append_at(:posts, %Post{title: "first"})
                   end
    end

    test "appends item at a sub field of a new list item" do
      changeset =
        %Category{id: 1, posts: []}
        |> change()
        |> append_at(:posts, %Post{title: "first"})
        |> append_at([:posts, 0, :comments], %Comment{})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :insert,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{}
                       }
                     ]
                   },
                   data: %Post{title: "first"}
                 }
               ]
             } = changeset.changes
    end

    test "appends item at a root level field with existing data" do
      changeset =
        %Category{id: 1, posts: [%Post{id: 1, title: "existing"}]}
        |> change()
        |> append_at(:posts, %Post{title: "first"})
        |> append_at(:posts, %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing"}
                 },
                 %Ecto.Changeset{action: :insert, data: %Post{title: "first"}},
                 %Ecto.Changeset{action: :insert, data: %Post{title: "second"}}
               ]
             } = changeset.changes
    end

    test "appends item at a nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{
              id: 1,
              title: "first",
              comments: [%Comment{id: 1}]
            },
            %Post{
              id: 2,
              title: "second",
              comments: []
            }
          ]
        }
        |> change()
        |> append_at([:posts, 1, :comments], %Comment{})
        |> append_at([:posts, 0, :comments], %Comment{})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{},
                         valid?: true
                       }
                     ]
                   },
                   data: %Post{}
                 },
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{}
                       }
                     ]
                   },
                   data: %Post{}
                 }
               ]
             } = changeset.changes
    end

    test "appends item to an array field" do
      changeset =
        %Category{id: 1, posts: [%Post{id: 1, title: "first", tags: ["one"]}]}
        |> change()
        |> append_at([:posts, 0, :tags], "two")

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["one", "two"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end
  end

  describe "prepend_at/3" do
    test "prepend item at a root level field without data" do
      changeset =
        %Category{id: 1, posts: []}
        |> change()
        |> prepend_at(:posts, %Post{title: "first"})
        |> prepend_at(:posts, %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{action: :insert, data: %Post{title: "second"}},
                 %Ecto.Changeset{action: :insert, data: %Post{title: "first"}}
               ]
             } = changeset.changes
    end

    test "doesn't raise error if field of unpersisted resource is not loaded" do
      %Category{id: 1}
      |> change()
      |> prepend_at(:posts, %Post{title: "first"})
    end

    test "raises error if field of persisted resource is not preloaded" do
      assert_raise EctoNestedChangeset.NotLoadedError,
                   "field `:posts` is not loaded",
                   fn ->
                     %Category{id: 1}
                     |> Map.update!(:__meta__, &Map.put(&1, :state, :loaded))
                     |> change()
                     |> prepend_at(:posts, %Post{title: "first"})
                   end
    end

    test "prepends item at a sub field of a new list item" do
      changeset =
        %Category{id: 1, posts: []}
        |> change()
        |> prepend_at(:posts, %Post{title: "first"})
        |> prepend_at([:posts, 0, :comments], %Comment{})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :insert,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{}
                       }
                     ]
                   },
                   data: %Post{title: "first"}
                 }
               ]
             } = changeset.changes
    end

    test "prepend item at a root level field with existing data" do
      changeset =
        %Category{id: 1, posts: [%Post{id: 1, title: "existing"}]}
        |> change()
        |> prepend_at(:posts, %Post{title: "first"})
        |> prepend_at(:posts, %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{action: :insert, data: %Post{title: "second"}},
                 %Ecto.Changeset{action: :insert, data: %Post{title: "first"}},
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing"}
                 }
               ]
             } = changeset.changes
    end

    test "prepend item at a nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{
              id: 1,
              title: "first",
              comments: [%Comment{id: 1}]
            },
            %Post{
              id: 2,
              title: "second",
              comments: []
            }
          ]
        }
        |> change()
        |> prepend_at([:posts, 1, :comments], %Comment{})
        |> prepend_at([:posts, 0, :comments], %Comment{})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       }
                     ]
                   },
                   data: %Post{}
                 },
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{}
                       }
                     ]
                   },
                   data: %Post{}
                 }
               ]
             } = changeset.changes
    end

    test "prepends item to an array field" do
      changeset =
        %Category{id: 1, posts: [%Post{id: 1, title: "first", tags: ["one"]}]}
        |> change()
        |> prepend_at([:posts, 0, :tags], "two")

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["two", "one"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end
  end

  describe "insert_at/3" do
    test "inserts item at a root level field without data" do
      changeset =
        %Category{id: 1, posts: []}
        |> change()
        |> insert_at([:posts, 0], %Post{title: "first"})
        |> insert_at([:posts, 0], %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{title: "second"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{title: "first"},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end

    test "doesn't raise error if field of unpersisted resource is not loaded" do
      %Category{id: 1}
      |> change()
      |> insert_at([:posts, 0], %Post{title: "first"})
    end

    test "raises error if field of persisted resource is not preloaded" do
      assert_raise EctoNestedChangeset.NotLoadedError,
                   "field `:posts` is not loaded",
                   fn ->
                     %Category{id: 1}
                     |> Map.update!(:__meta__, &Map.put(&1, :state, :loaded))
                     |> change()
                     |> insert_at([:posts, 0], %Post{title: "first"})
                   end
    end

    test "inserts item at a sub field of a new list item" do
      changeset =
        %Category{id: 1, posts: []}
        |> change()
        |> insert_at([:posts, 0], %Post{title: "first"})
        |> insert_at([:posts, 0, :comments, 0], %Comment{})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :insert,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{}
                       }
                     ]
                   },
                   data: %Post{title: "first"}
                 }
               ]
             } = changeset.changes
    end

    test "inserts item at a root level field with existing data" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "existing 1"},
            %Post{id: 2, title: "existing 2"},
            %Post{id: 3, title: "existing 3"}
          ]
        }
        |> change()
        |> insert_at([:posts, 2], %Post{title: "first"})
        |> insert_at([:posts, 1], %Post{title: "second"})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing 1"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{title: "second"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing 2"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{title: "first"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "existing 3"},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end

    test "inserts item at a nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{
              id: 1,
              title: "first",
              comments: [%Comment{id: 1}, %Comment{id: 2}, %Comment{id: 3}]
            },
            %Post{
              id: 2,
              title: "second",
              comments: [%Comment{id: 4}, %Comment{id: 5}]
            }
          ]
        }
        |> change()
        |> insert_at([:posts, 0, :comments, 3], %Comment{})
        |> insert_at([:posts, 1, :comments, 1], %Comment{})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :insert,
                         data: %Comment{},
                         valid?: true
                       }
                     ]
                   },
                   data: %Post{},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{action: :update, data: %Comment{}},
                       %Ecto.Changeset{action: :insert, data: %Comment{}},
                       %Ecto.Changeset{action: :update, data: %Comment{}}
                     ]
                   },
                   data: %Post{}
                 }
               ]
             } = changeset.changes
    end

    test "inserts item into array field" do
      changeset =
        %Category{id: 1, posts: [%Post{title: "first", tags: ["one", "two"]}]}
        |> change()
        |> insert_at([:posts, 0, :tags, 1], "three")

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["one", "three", "two"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end
  end

  describe "update_at/3" do
    test "updates a field" do
      changeset =
        %Category{id: 1, posts: [%Post{id: 1, title: "first"}]}
        |> change()
        |> update_at([:posts, 0, :title], &String.reverse/1)
        |> append_at([:posts], %Post{title: "second"})
        |> update_at([:posts, 1, :title], &String.duplicate(&1, 2))

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{},
                   changes: %{title: "tsrif"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{},
                   changes: %{title: "secondsecond"},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end

    test "flip flop a field many times" do
      changeset =
        %Category{id: 1, blocks: [%Block{text: "jack"}]}
        |> change()
        |> append_at([:blocks], %Block{text: "mathias"})
        |> update_at([:blocks, 1, :text], fn _ -> "jack" end)
        |> update_at([:blocks, 0, :text], fn _ -> "mathias" end)
        |> update_at([:blocks, 1, :text], fn _ -> "jack" end)
        |> update_at([:blocks, 0, :text], fn _ -> "mathias" end)
        |> update_at([:blocks, 1, :text], fn _ -> "jack" end)
        |> update_at([:blocks, 0, :text], fn _ -> "mathias" end)

      assert %{
               blocks: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Block{},
                   changes: %{text: "mathias"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Block{},
                   changes: %{text: "jack"},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end

    # test "flip flops existing item" do
    #   changeset =
    #     %Category{blocks: [%Block{text: "jack"}]}
    #     |> change()
    #     |> append_at([:blocks], %Block{text: "mathias"})
    #     |> Ecto.Changeset.apply_changes()

    #   category = Ecto.Repo.insert(%Category{blocks: [%Block{text: "jack"}]})

    #   IO.inspect(category)

    test "updates a list field" do
      changeset =
        %Category{
          id: 1,
          posts: [%Post{id: 1, title: "first"}, %Post{id: 2, title: "second"}]
        }
        |> change()
        |> append_at([:posts], %Post{title: "third"})
        |> update_at(
          [:posts],
          &Enum.map(&1, fn post_changeset ->
            title = get_field(post_changeset, :title)
            put_change(post_changeset, :title, String.reverse(title))
          end)
        )

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{id: 1},
                   changes: %{title: "tsrif"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{id: 2},
                   changes: %{title: "dnoces"},
                   valid?: true
                 },
                 %Ecto.Changeset{
                   action: :insert,
                   data: %Post{},
                   changes: %{title: "driht"},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end

    test "updates item in array field" do
      changeset =
        %Category{id: 1, posts: [%Post{title: "first", tags: ["one", "two"]}]}
        |> change()
        |> append_at([:posts, 0, :tags], "three")
        |> update_at([:posts, 0, :tags, 1], &String.reverse/1)

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["one", "owt", "three"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end

    test "updates array field" do
      changeset =
        %Category{id: 1, posts: [%Post{title: "first", tags: ["one", "two"]}]}
        |> change()
        |> append_at([:posts, 0, :tags], "three")
        |> update_at(
          [:posts, 0, :tags],
          &Enum.map(&1, fn tag -> String.reverse(tag) end)
        )

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["eno", "owt", "eerht"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end
  end

  describe "delete_at/3" do
    test "deletes item from changes that isn't persisted yet" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "one"},
            %Post{id: 2, title: "two"}
          ]
        }
        |> change()
        |> append_at([:posts], %Post{title: "three"})
        |> delete_at([:posts, 2])

      assert changeset.changes == %{}
    end

    test "deletes existing item" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "one"},
            %Post{id: 2, title: "two"},
            %Post{id: 3, title: "three"}
          ]
        }
        |> change()
        |> delete_at([:posts, 1])

      assert %{
               posts: [
                 %Changeset{action: :replace, data: %Post{id: 2}},
                 %Changeset{action: :update, data: %Post{id: 1}},
                 %Changeset{action: :update, data: %Post{id: 3}}
               ]
             } = changeset.changes
    end

    test "puts delete action for persisted data" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "one"},
            %Post{id: 2, title: "two"},
            %Post{id: 3, title: "three"}
          ]
        }
        |> change()
        |> prepend_at([:posts], %Post{})
        |> delete_at([:posts, 2], mode: {:action, :delete})
        |> delete_at([:posts, 0], mode: {:action, :delete})

      assert %{
               posts: [
                 %Changeset{action: :update, data: %Post{id: 1}},
                 %Changeset{action: :delete, data: %Post{id: 2}},
                 %Changeset{action: :update, data: %Post{id: 3}}
               ]
             } = changeset.changes
    end

    test "removes persisted data from list with replace option" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "one"},
            %Post{id: 2, title: "two"},
            %Post{id: 3, title: "three"}
          ]
        }
        |> change()
        |> prepend_at([:posts], %Post{})
        |> delete_at([:posts, 0], mode: {:action, :replace})
        |> delete_at([:posts, 1], mode: {:action, :replace})

      assert %{
               posts: [
                 %Changeset{action: :replace, data: %Post{id: 2}},
                 %Changeset{action: :update, data: %Post{id: 1}},
                 %Changeset{action: :update, data: %Post{id: 3}}
               ]
             } = changeset.changes
    end

    test "puts change on delete field from list with flag option" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "one"},
            %Post{id: 2, title: "two"},
            %Post{id: 3, title: "three"}
          ]
        }
        |> change()
        |> prepend_at([:posts], %Post{})
        |> delete_at([:posts, 0], mode: {:flag, :delete})
        |> delete_at([:posts, 1], mode: {:flag, :delete})

      assert %{
               posts: [
                 %Changeset{action: :update, data: %Post{id: 1}, valid?: true},
                 %Changeset{
                   action: :update,
                   changes: %{delete: true},
                   data: %Post{id: 2},
                   valid?: true
                 },
                 %Changeset{action: :update, data: %Post{id: 3}, valid?: true}
               ]
             } = changeset.changes
    end

    test "deletes item from changes in nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{id: 1, title: "one"},
            %Post{
              id: 2,
              title: "two",
              comments: [%Comment{id: 1}, %Comment{id: 2}]
            }
          ]
        }
        |> change()
        |> append_at([:posts, 1, :comments], %Comment{})
        |> delete_at([:posts, 1, :comments, 2])

      assert changeset.changes == %{}
    end

    test "deletes existing item from a nested field" do
      changeset =
        %Category{
          id: 1,
          posts: [
            %Post{
              id: 1,
              title: "first",
              comments: [%Comment{id: 1}, %Comment{id: 2}, %Comment{id: 3}]
            },
            %Post{
              id: 2,
              title: "second",
              comments: [%Comment{id: 4}, %Comment{id: 5}]
            }
          ]
        }
        |> change()
        |> delete_at([:posts, 1, :comments, 0], mode: {:action, :delete})
        |> delete_at([:posts, 0, :comments, 1], mode: {:action, :delete})

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{id: 1},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :delete,
                         data: %Comment{id: 2},
                         valid?: true
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{id: 3},
                         valid?: true
                       }
                     ]
                   },
                   data: %Post{}
                 },
                 %Ecto.Changeset{
                   action: :update,
                   changes: %{
                     comments: [
                       %Ecto.Changeset{
                         action: :delete,
                         data: %Comment{id: 4}
                       },
                       %Ecto.Changeset{
                         action: :update,
                         data: %Comment{id: 5}
                       }
                     ]
                   },
                   data: %Post{}
                 }
               ]
             } = changeset.changes
    end

    test "deletes item from an array field" do
      changeset =
        %Category{
          id: 1,
          posts: [%Post{title: "first", tags: ["one", "two", "three"]}]
        }
        |> change()
        |> delete_at([:posts, 0, :tags, 1])

      assert %{
               posts: [
                 %Ecto.Changeset{
                   action: :update,
                   data: %Post{title: "first"},
                   changes: %{tags: ["one", "three"]},
                   valid?: true
                 }
               ]
             } = changeset.changes
    end
  end

  describe "get_at/2" do
    test "gets a field of a nested item" do
      field =
        %Category{id: 1, posts: [%Post{id: 1, title: "first"}]}
        |> change()
        |> get_at([:posts, 0, :title])

      assert field == "first"
    end

    test "gets a list of nested items" do
      field =
        %Category{
          id: 1,
          posts: [%Post{id: 1, title: "first"}, %Post{id: 2, title: "second"}]
        }
        |> change()
        |> get_at([:posts])

      assert field == [
               %Post{id: 1, title: "first"},
               %Post{id: 2, title: "second"}
             ]
    end

    test "gets item in an array field" do
      field =
        %Category{id: 1, posts: [%Post{title: "first", tags: ["one", "two"]}]}
        |> change()
        |> get_at([:posts, 0, :tags, 1])

      assert field == "two"
    end

    test "doesn't raise error if resource field is not loaded" do
      %Category{id: 1}
      |> change()
      |> get_at([:posts])
    end
  end
end
