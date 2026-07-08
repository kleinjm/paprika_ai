module Paprika
  # Raised when something tries to mutate the local Paprika mirror outside of a
  # sync. The mirror is a read-only cache — see ApplicationRecord below.
  class ReadOnlyMirrorError < StandardError; end

  # The local Paprika tables (ZRECIPE, categories, meals, …) are a **read-only
  # cache of the Paprika cloud**, populated by PaprikaSync pulling cloud →
  # mirror. The cloud is the single source of truth.
  #
  # All app-initiated changes must be written to the cloud through PaprikaCloud;
  # the new value then flows back into this cache via a sync. To keep that
  # invariant honest, every persistence path through these models raises unless
  # it runs inside `Paprika::ApplicationRecord.syncing { … }` — the block that
  # PaprikaSync (and the cache-refresh in the cloud push helpers) use.
  #
  # Note: `insert_all` / `upsert_all` / `delete_all` bypass ActiveRecord
  # callbacks and therefore this guard. They exist only inside PaprikaSync,
  # which already runs under `syncing`; don't reach for them elsewhere to work
  # around the guard.
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # Per-thread flag: are we currently applying a cloud → mirror sync?
    thread_mattr_accessor :sync_in_progress, instance_accessor: false

    # Wrap cloud → mirror writes. Only PaprikaSync and the cache-refresh step of
    # PaprikaCloud's push helpers should open this window.
    def self.syncing
      previous = sync_in_progress
      self.sync_in_progress = true
      yield
    ensure
      self.sync_in_progress = previous
    end

    before_save :ensure_syncing!
    before_destroy :ensure_syncing!

    private

    def ensure_syncing!
      return if self.class.sync_in_progress

      raise ReadOnlyMirrorError,
            "#{self.class.name} is a read-only cache of the Paprika cloud. " \
            "Write the change to the cloud via PaprikaCloud and let PaprikaSync " \
            "refresh the mirror."
    end
  end
end
