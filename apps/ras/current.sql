--
-- PostgreSQL database dump
--

\restrict 0IgmLidEHxBYyNMjJDn3kdEZ2UKjoxbaW6ajq8xaJv7EjPZWcuT2kehnUXhb7fv

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: inet_endpoint; Type: TYPE; Schema: public; Owner: ras
--

CREATE TYPE public.inet_endpoint AS (
	address inet,
	port smallint
);


ALTER TYPE public.inet_endpoint OWNER TO ras;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _sqlx_migrations; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public._sqlx_migrations (
    version bigint NOT NULL,
    description text NOT NULL,
    installed_on timestamp with time zone DEFAULT now() NOT NULL,
    success boolean NOT NULL,
    checksum bytea NOT NULL,
    execution_time bigint NOT NULL
);


ALTER TABLE public._sqlx_migrations OWNER TO ras;

--
-- Name: home; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.home (
    id uuid NOT NULL,
    hostname text NOT NULL,
    nixos_closure_state_id uuid
);


ALTER TABLE public.home OWNER TO ras;

--
-- Name: host; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.host (
    id uuid NOT NULL,
    name text NOT NULL,
    nixos_closure_state_id uuid
);


ALTER TABLE public.host OWNER TO ras;

--
-- Name: ipam_address_allocation; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.ipam_address_allocation (
    id uuid CONSTRAINT address_allocation_id_not_null NOT NULL,
    name text CONSTRAINT address_allocation_name_not_null NOT NULL,
    parent_id uuid,
    cidr cidr CONSTRAINT address_allocation_cidr_not_null NOT NULL
);


ALTER TABLE public.ipam_address_allocation OWNER TO ras;

--
-- Name: ipam_live_ip; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.ipam_live_ip (
    id uuid NOT NULL,
    host_id uuid NOT NULL,
    address inet NOT NULL,
    interface_name text NOT NULL,
    allocation_id uuid
);


ALTER TABLE public.ipam_live_ip OWNER TO ras;

--
-- Name: nixos_closure; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.nixos_closure (
    id uuid NOT NULL,
    name text NOT NULL,
    latest_store_path text NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.nixos_closure OWNER TO ras;

--
-- Name: nixos_closure_state; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.nixos_closure_state (
    id uuid NOT NULL,
    closure_id uuid NOT NULL,
    current_store_path text NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.nixos_closure_state OWNER TO ras;

--
-- Name: versions; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.versions (
    versioned_item text NOT NULL,
    store_path text NOT NULL,
    version bigint NOT NULL
);


ALTER TABLE public.versions OWNER TO ras;

--
-- Name: wiregurard_tunnel; Type: TABLE; Schema: public; Owner: ras
--

CREATE TABLE public.wiregurard_tunnel (
    id uuid NOT NULL,
    initiator_id uuid NOT NULL,
    initiator_ip_id uuid NOT NULL,
    responder_id uuid NOT NULL,
    responder_ip_id uuid NOT NULL,
    responder_port integer NOT NULL
);


ALTER TABLE public.wiregurard_tunnel OWNER TO ras;

--
-- Name: _sqlx_migrations _sqlx_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public._sqlx_migrations
    ADD CONSTRAINT _sqlx_migrations_pkey PRIMARY KEY (version);


--
-- Name: ipam_address_allocation address_allocation_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.ipam_address_allocation
    ADD CONSTRAINT address_allocation_pkey PRIMARY KEY (id);


--
-- Name: home home_hostname_key; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.home
    ADD CONSTRAINT home_hostname_key UNIQUE (hostname);


--
-- Name: home home_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.home
    ADD CONSTRAINT home_pkey PRIMARY KEY (id);


--
-- Name: host host_name_key; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.host
    ADD CONSTRAINT host_name_key UNIQUE (name);


--
-- Name: host host_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.host
    ADD CONSTRAINT host_pkey PRIMARY KEY (id);


--
-- Name: ipam_live_ip ipam_live_ip_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.ipam_live_ip
    ADD CONSTRAINT ipam_live_ip_pkey PRIMARY KEY (id);


--
-- Name: nixos_closure nixos_closure_name_key; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.nixos_closure
    ADD CONSTRAINT nixos_closure_name_key UNIQUE (name);


--
-- Name: nixos_closure nixos_closure_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.nixos_closure
    ADD CONSTRAINT nixos_closure_pkey PRIMARY KEY (id);


--
-- Name: nixos_closure_state nixos_closure_state_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.nixos_closure_state
    ADD CONSTRAINT nixos_closure_state_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (versioned_item, store_path);


--
-- Name: wiregurard_tunnel wiregurard_tunnel_pkey; Type: CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.wiregurard_tunnel
    ADD CONSTRAINT wiregurard_tunnel_pkey PRIMARY KEY (id);


--
-- Name: ipam_address_allocation address_allocation_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.ipam_address_allocation
    ADD CONSTRAINT address_allocation_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.ipam_address_allocation(id);


--
-- Name: home home_nixos_closure_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.home
    ADD CONSTRAINT home_nixos_closure_state_id_fkey FOREIGN KEY (nixos_closure_state_id) REFERENCES public.nixos_closure_state(id);


--
-- Name: host host_nixos_closure_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.host
    ADD CONSTRAINT host_nixos_closure_state_id_fkey FOREIGN KEY (nixos_closure_state_id) REFERENCES public.nixos_closure_state(id);


--
-- Name: ipam_live_ip ipam_live_ip_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.ipam_live_ip
    ADD CONSTRAINT ipam_live_ip_allocation_id_fkey FOREIGN KEY (allocation_id) REFERENCES public.ipam_address_allocation(id);


--
-- Name: ipam_live_ip ipam_live_ip_host_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.ipam_live_ip
    ADD CONSTRAINT ipam_live_ip_host_fkey FOREIGN KEY (host) REFERENCES public.host(id);


--
-- Name: nixos_closure_state nixos_closure_state_closure_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.nixos_closure_state
    ADD CONSTRAINT nixos_closure_state_closure_id_fkey FOREIGN KEY (closure_id) REFERENCES public.nixos_closure(id);


--
-- Name: wiregurard_tunnel wiregurard_tunnel_initiator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.wiregurard_tunnel
    ADD CONSTRAINT wiregurard_tunnel_initiator_id_fkey FOREIGN KEY (initiator_id) REFERENCES public.host(id);


--
-- Name: wiregurard_tunnel wiregurard_tunnel_initiator_ip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.wiregurard_tunnel
    ADD CONSTRAINT wiregurard_tunnel_initiator_ip_id_fkey FOREIGN KEY (initiator_ip_id) REFERENCES public.ipam_live_ip(id);


--
-- Name: wiregurard_tunnel wiregurard_tunnel_responder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.wiregurard_tunnel
    ADD CONSTRAINT wiregurard_tunnel_responder_id_fkey FOREIGN KEY (responder_id) REFERENCES public.host(id);


--
-- Name: wiregurard_tunnel wiregurard_tunnel_responder_ip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ras
--

ALTER TABLE ONLY public.wiregurard_tunnel
    ADD CONSTRAINT wiregurard_tunnel_responder_ip_id_fkey FOREIGN KEY (responder_ip_id) REFERENCES public.ipam_live_ip(id);


--
-- PostgreSQL database dump complete
--

\unrestrict 0IgmLidEHxBYyNMjJDn3kdEZ2UKjoxbaW6ajq8xaJv7EjPZWcuT2kehnUXhb7fv

