// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Ticket } from '#shared/graphql/types.ts'

import HistoryEventDetailsMerge from '../HistoryEventDetails/HistoryEventDetailsMerge.vue'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'received-merge',
  actionName: __('Merged ticket'),
  component: HistoryEventDetailsMerge,
  content: (event) => {
    const ticket = event.object as Ticket

    const details = `#${ticket.number}`

    return {
      description: __('into this ticket'),
      details,
      link: `/tickets/${ticket.internalId}`,
    }
  },
}
