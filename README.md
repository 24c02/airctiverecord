# AirctiveRecord

activerecord-ish API for airtable, built on [norairrecord](https://github.com/24c02/norairrecord)

## what you get

* **chainable queries** via [Airrel](https://github.com/24c02/airrel) - lazy-loading relations just like ActiveRecord
* activemodel validations (presence, format, numericality, etc.)
* activemodel callbacks (before_save, after_create, etc.)
* activemodel dirty tracking (changed? / was / change)
* activerecord-style attributes with `field` mappings for airtable fields with spaces
* chainable scopes that return relations
* associations (has_many, belongs_to, has_one, through:)
* all the norairrecord goodness (batch ops, transactions, comments, STI, etc.)

## installation

```ruby
gem 'airctiverecord'
```

```bash
bundle install
```

## setup

```ruby
Norairrecord.api_key = ENV['AIRTABLE_API_KEY']

class AirpplicationRecord < AirctiveRecord::Base
  self.base_key = ENV['AIRTABLE_BASE_KEY']
end
```

## usage

### basic model

```ruby
class User < AirpplicationRecord
  self.table_name = "Users"
  
  # map ruby names to airtable field names
  field :first_name, "First Name"
  field :last_name, "Last Name"
  field :email, "Email Address"
  field :phone, "Phone Number"
  
  # validations
  validates :first_name, :last_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  # callbacks
  before_save :normalize_email
  after_create :send_welcome_email
  
  private
  
  def normalize_email
    self.email = email&.downcase&.strip
  end
  
  def send_welcome_email
    # ...
  end
end
```

### field mappings

lots of airtable fields have spaces, ruby doesn't like that. use `field`:

```ruby
class Contact < AirpplicationRecord
  self.table_name = "Contacts"
  
  field :first_name, "First Name"
  field :company_name, "Company Name"
  field :is_vip, "VIP?"
  field :date_added, "Date Added"
end

contact = Contact.new(
  first_name: "Jane",      # writes to "First Name"
  company_name: "Acme",    # writes to "Company Name"
  is_vip: true             # writes to "VIP?"
)

contact.first_name         # => "Jane"
contact.first_name?        # => true (presence check)
contact.first_name_changed? # => dirty tracking works
```

### CRUD

```ruby
# create
user = User.create(first_name: "Alice", email: "alice@example.com")
user = User.create!(first_name: "Alice", email: "alice@example.com") # raises on validation error

# read
user = User.find("recXXXXXXXXXXXXXX")
users = User.all
user = User.first
user = User.find_by(email: "alice@example.com")
user = User.find_by!(email: "alice@example.com") # raises if not found

# update
user.update(first_name: "Alicia")
user.first_name = "Alicia"
user.save
user.update!(first_name: "Alicia") # raises on validation error

# delete
user.destroy

# reload
user.reload
```

### querying (now with chainable relations!)

```ruby
# chainable queries (powered by Airrel)
User.where(role: "admin").where(active: true).order(created_at: :desc).limit(10)

# hash queries (converted to airtable formulas)
User.where(role: "admin", active: true)
User.where(age: 18..65)           # range queries
User.where(role: ["admin", "mod"]) # IN queries
User.where(email: nil)            # BLANK() checks

# raw airtable formulas still work
User.where("{Age} > 18")
User.where("AND({Email} != '', {Active} = TRUE())")

# sorting
User.order(:name)
User.order(name: :asc, age: :desc)
User.order(:created_at).reverse_order

# limiting
User.limit(10)
User.offset(20)

# lazy loading - queries don't execute until you iterate
users = User.where(role: "admin") # no API call yet
users.each { |u| puts u.name }     # now it executes

# scopes are chainable now!
class User < AirpplicationRecord
  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: "admin") }
  scope :recent, -> { order(created_at: :desc).limit(10) }
end

User.active.admins.recent # chains perfectly!
```

### validations

```ruby
class User < AirctiveRecord::Base
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than_or_equal_to: 18 }
  validates :username, length: { minimum: 3, maximum: 20 }
  validates :role, inclusion: { in: %w[admin user guest] }
  
  validate :custom_validation
  
  private
  
  def custom_validation
    errors.add(:base, "nope") if some_condition?
  end
end

user = User.new(email: "invalid")
user.valid?                    # => false
user.errors.full_messages      # => ["Email is invalid"]
user.save                      # => false
user.save!                     # => raises AirctiveRecord::RecordInvalid
```

### callbacks

```ruby
class User < AirctiveRecord::Base
  before_validation :normalize_data
  after_validation :log_errors
  
  before_save :encrypt_password
  after_save :clear_cache
  
  before_create :set_defaults
  after_create :send_notification
  
  before_update :check_changes
  after_update :sync_with_service
  
  before_destroy :cleanup_associations
  after_destroy :log_deletion
end
```

### dirty tracking

```ruby
user = User.find("recXXX")
user.first_name = "New Name"

user.changed?               # => true
user.first_name_changed?    # => true
user.first_name_was         # => "Old Name"
user.first_name_change      # => ["Old Name", "New Name"]
user.changes                # => { "first_name" => ["Old Name", "New Name"] }

user.save
user.changed?               # => false
```

### norairrecord features

you still get all of norairrecord since we inherit from it:

```ruby
# batch ops
User.batch_create([user1, user2, user3])
User.batch_update([user1, user2, user3])
User.batch_upsert(users, ["Email"])

# transactions
user.transaction do |u|
  u["First Name"] = "New Name"
  u["Email"] = "new@example.com"
end

# comments
user.comment("great customer!")

# direct field access
user["Custom Field Name"] = "value"

# airtable URL
user.airtable_url # => "https://airtable.com/appXXX/tblYYY/recZZZ"

# subtypes
class Animal < AirctiveRecord::Base
  has_subtypes "Type", {
    "dog" => "Dog",
    "cat" => "Cat"
  }
end

class Dog < Animal; end
class Cat < Animal; end

Animal.all # => [<Dog>, <Cat>, <Dog>]
```

## security & escaping

string values are properly escaped using airtable's formula syntax (backslash escaping):

```ruby
User.where(name: "O'Reilly")  
# => {name} = 'O\'Reilly'

Contact.where(email: "test') & malicious")
# => safe! escaped to "{email} = 'test\') & malicious'"
```

field names from `field` mappings are used as-is. if you're dynamically generating field names from user input, validate them first.

## architecture

**relation classes**

each model automatically gets its own Relation subclass. this means:
- scopes are isolated per model (User.active doesn't pollute Post)
- field mappings are applied correctly
- you can define model-specific query methods

```ruby
User.relation_class        # => User's own Relation class
Post.relation_class        # => Post's own Relation class  
User.relation_class == Post.relation_class  # => false
```

**query flow**

1. `User.where(role: "admin")` → creates a `User::Relation` instance
2. `.where(active: true)` → returns new relation with merged conditions
3. `.order(:name)` → returns new relation with ordering
4. `.to_a` or `.each` → executes the query via norairrecord

field mappings are applied when:
- building formulas from hash conditions
- converting field names in order clauses
- accessing attributes on records

## performance

**count is expensive**

`.count` loads all matching records. use `.any?` or `.exists?` to check existence:

```ruby
User.where(role: "admin").count   # loads ALL admins
User.where(role: "admin").any?    # only loads 1 record ✓
```

**first/last are optimized**

automatically use `limit(1)` to avoid loading unnecessary records:

```ruby
User.first       # limit(1)
User.last        # limit(1) with reversed order
User.first(10)   # limit(10)
```

**large tables**

for tables with 25k+ records, process in batches:

```ruby
# batch processing
offset = 0
loop do
  batch = User.limit(100).offset(offset).to_a
  break if batch.empty?
  batch.each { |user| process(user) }
  offset += 100
end
```

## license

MIT
