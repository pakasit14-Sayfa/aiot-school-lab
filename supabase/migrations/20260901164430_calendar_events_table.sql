CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_type TEXT NOT NULL CHECK (event_type IN ('holiday', 'public_holiday', 'exam', 'activity', 'study')),
    start_date DATE NOT NULL,
    end_date DATE,
    target_grades TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- Allow read for authenticated users in the school (parents, teachers, etc)
CREATE POLICY "Allow read access to calendar_events for school members" ON public.calendar_events
    FOR SELECT TO authenticated
    USING (
        school_id IN (
            SELECT school_id FROM public.users WHERE id = auth.uid()
        ) OR
        school_id IN (
            SELECT school_id FROM public.students WHERE parent_id = auth.uid()
        )
    );
