<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTemplateRef, type Ref } from 'vue'

import { useOnlineNotificationActions } from '#shared/entities/online-notification/composables/useOnlineNotificationActions.ts'
import { useOnlineNotificationCount } from '#shared/entities/online-notification/composables/useOnlineNotificationCount.ts'
import { useOnlineNotificationList } from '#shared/entities/online-notification/composables/useOnlineNotificationList.ts'
import type { OnlineNotification } from '#shared/graphql/types.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import NotificationHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationHeader.vue'
import NotificationList from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationList.vue'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'

let mutationTriggered = false

const { notificationsCountSubscription } = useOnlineNotificationCount()

const {
  notificationList,
  loading: isLoading,
  hasUnseenNotification,
  refetch,
} = useOnlineNotificationList()

notificationsCountSubscription.watchOnResult(() => {
  refetch()
  if (!mutationTriggered) refetch()
  mutationTriggered = false
})

const emit = defineEmits<{
  close: []
}>()

const sectionElement = useTemplateRef('section')

const { reachedTop } = useElementScroll(sectionElement as Ref<HTMLElement>)

const { seenNotification, markAllRead, deleteNotification } =
  useOnlineNotificationActions()

const runSeenNotification = async (notification: OnlineNotification) => {
  mutationTriggered = true

  emit('close')

  return seenNotification(notification.id).then(() => {
    mutationTriggered = false
  })
}

const removeNotification = async (notification: OnlineNotification) =>
  deleteNotification(notification.id)

const runMarkAllRead = async () => {
  mutationTriggered = true

  const ids = notificationList.value.map((notification) => notification.id)

  return markAllRead(ids).then(() => {
    mutationTriggered = false
  })
}
</script>

<template>
  <!-- min height is required to prevent scrollbar to show on initial load -->
  <section ref="section" class="max-h-full w-[400px]">
    <NotificationHeader
      class="sticky top-0 z-10 mb-2 bg-neutral-50 px-3 py-3 dark:bg-gray-500"
      :class="{
        'border-b border-b-neutral-300 dark:border-b-gray-900': !reachedTop,
      }"
      :has-unseen-notification="hasUnseenNotification"
      @mark-all="runMarkAllRead"
    />
    <CommonLoader :loading="isLoading">
      <NotificationList
        :list="notificationList"
        @seen="runSeenNotification"
        @remove="removeNotification"
      />
    </CommonLoader>
  </section>
</template>
